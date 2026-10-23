/*****************************************************************
  * DOWNSCALING CLIMATOLOGICO Y ESTRES HIDRICO - PROVINCIA DE ANTA -- v4.1
* Configuracion de exportacion optimizada:
  *   - Series anuales (2001-2025) compiladas en 2 archivos GeoTIFF Multibanda
*     (25 bandas por archivo: T_2001..T_2025 y P_2001..P_2025).
*   - Predictores finos (30 m): SRTM (elev, pendiente, northness) + Sentinel-2 (NDMI, NDVI).
*   - Analisis de Variabilidad (Desv. Est., CV) y Tendencias decadales.
*   - Modelo espacial de Probabilidad de Estres Hidrico (WSI).
*****************************************************************/
  
  // ---------- 1. PARAMETROS ----------
  var Y0 = 2001, Y1 = 2025;                  // Periodo de analisis (25 anios completos)
  var SCALE_OUT = 30;                        // Resolucion espacial de exportacion (m)
  var SCALE_STATS = 100;                     // Resolucion para estadisticos provinciales (m)
  var CRS_OUT = 'EPSG:32718';                // UTM Zona 18S
  var FOLDER_OUT = 'Clima_Anta';             // Carpeta en Google Drive
  var PERIODO = Y0 + '_' + Y1;
  
  // ---------- 2. AREA DE ESTUDIO ----------
    var geometry = ee.FeatureCollection('projects/ee-efren/assets/provincia_anta');
  var roi = geometry.geometry();
  var fitRegion = roi.buffer(40000);         // Buffer de 40 km para ajuste regional
  Map.centerObject(roi, 10);
  
  var start = ee.Date.fromYMD(Y0, 1, 1);
  var end = ee.Date.fromYMD(Y1 + 1, 1, 1);
  var nYears = Y1 - Y0 + 1;
  
  // ---------- 3. TOPOGRAFIA Y HUMEDAD SENTINEL-2 (PREDICTORES A 30 m) ----------
    var dem = ee.Image('USGS/SRTMGL1_003').rename('elev');
  var demProj = dem.projection();
  
  // Morfometria derivada de SRTM
  var terrain = ee.Terrain.products(dem);
  var slope = terrain.select('slope').rename('slope');
  var aspectRad = terrain.select('aspect').multiply(Math.PI / 180);
  var northness = aspectRad.cos().rename('northness'); // +1 = Exposicion Norte (mayor insolacion)
  
  var ll = ee.Image.pixelLonLat();
  
  // Mascara de nubes y sombras para Sentinel-2 SR
  function maskS2clouds(image) {
    var qa = image.select('QA60');
    var scl = image.select('SCL');
    var cloudBitMask = 1 << 10;
    var cirrusBitMask = 1 << 11;
    var mask = qa.bitwiseAnd(cloudBitMask).eq(0)
    .and(qa.bitwiseAnd(cirrusBitMask).eq(0))
    .and(scl.neq(3)).and(scl.neq(8)).and(scl.neq(9)).and(scl.neq(10));
    return image.updateMask(mask).divide(10000);
  }
  
  var s2Col = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(fitRegion)
  .filterDate('2019-01-01', '2026-01-01') // fin exclusivo: incluye todo 2025
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 40))
  .map(maskS2clouds);
  
  var s2Median = s2Col.median();
  
  // NDMI (Humedad vegetacion/suelo) y NDVI (Vigor fotosintetico)
  var ndmi = s2Median.normalizedDifference(['B8', 'B11']).rename('ndmi')
  .unmask(0).resample('bilinear').reproject({crs: demProj, scale: 30});
  var ndvi = s2Median.normalizedDifference(['B8', 'B4']).rename('ndvi')
  .unmask(0).resample('bilinear').reproject({crs: demProj, scale: 30});
  
  var predFine = dem
  .addBands(slope)
  .addBands(northness)
  .addBands(ndmi)
  .addBands(ndvi)
  .addBands(ll.select('longitude').rename('lon'))
  .addBands(ll.select('latitude').rename('lat'))
  .setDefaultProjection(demProj);
  
  var bands = predFine.bandNames();
  print('Covariables predictoras (30 m):', bands);
  
  // Agregacion espacial en dos pasos (30 m -> 1 km -> resolucion nativa de reanalisis)
  function coarsen(img, proj) {
    return img.setDefaultProjection(demProj)
    .reduceResolution({reducer: ee.Reducer.mean(), maxPixels: 4096})
    .reproject({crs: 'EPSG:4326', scale: 1000})
    .reduceResolution({reducer: ee.Reducer.mean(), maxPixels: 4096})
    .reproject(proj);
  }
  
  // ---------- 4. TEMPERATURA (DOWNSCALING CON GRADIENTE + AJUSTE TOPOCLIMATICO) ----------
    var eraCol = ee.ImageCollection('ECMWF/ERA5_LAND/MONTHLY_AGGR');
  var eraProj = eraCol.first().projection();
  var era = eraCol.filterDate(start, end).select('temperature_2m').mean()
  .subtract(273.15).rename('T').setDefaultProjection(eraProj);
  
  var zCoarse = coarsen(dem, eraProj);
  
  var fit = zCoarse.addBands(era).reduceRegion({
    reducer: ee.Reducer.linearFit(), geometry: fitRegion,
    scale: eraProj.nominalScale(), maxPixels: 1e9, bestEffort: true
  });
  var lapse = ee.Number(fit.get('scale'));
  print('Gradiente termico vertical estimado (degC/km):', lapse.multiply(1000));
  
  var ndmiCoarse = coarsen(ndmi, eraProj);
  var deltaZ = dem.subtract(zCoarse.resample('bilinear'));
  var deltaNDMI = ndmi.subtract(ndmiCoarse.resample('bilinear'));
  
  // Correccion por elevacion + enfriamiento evaporativo local (NDMI) + insolacion (northness)
  var topoCorr = deltaZ.multiply(ee.Image.constant(lapse))
  .add(deltaNDMI.multiply(-0.8))
  .add(northness.multiply(0.3));
  
  var Tfine = era.resample('bilinear').add(topoCorr)
  .rename('T_down').clip(roi);
  
  // ---------- 5. PRECIPITACION (DOWNSCALING RF CON SENTINEL-2 + RESIDUAL) ----------
    var chirpsCol = ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY');
  var cProj = chirpsCol.first().projection();
  var chirps = chirpsCol.filterDate(start, end).select('precipitation').sum()
  .divide(nYears).rename('P').setDefaultProjection(cProj);
  
  var predCoarse = coarsen(predFine, cProj);
  
  var train = predCoarse.addBands(chirps).sample({
    region: fitRegion, projection: cProj, numPixels: 6000, seed: 7
  });
  
  var rf = ee.Classifier.smileRandomForest({
    numberOfTrees: 250,
    minLeafPopulation: 3,
    seed: 7
  }).setOutputMode('REGRESSION').train(train, 'P', bands);
  
  print('Importancia de variables en RF Precipitacion:', rf.explain());
  
  var residual = chirps.subtract(predCoarse.classify(rf));
  var Pfine = predFine.classify(rf)
  .add(residual.resample('bilinear')).max(0).rename('P_down').clip(roi);
  
  // ---------- 6. SERIES ANUALES Y COMPILACION MULTIBANDA ----------
    var years = ee.List.sequence(Y0, Y1);
  
  // Coleccion anual de Temperatura
  var Tyears = ee.ImageCollection(years.map(function(y) {
    y = ee.Number(y);
    var s = ee.Date.fromYMD(y, 1, 1), e = s.advance(1, 'year');
    var eraY = eraCol.filterDate(s, e).select('temperature_2m').mean()
    .subtract(273.15).setDefaultProjection(eraProj);
    var timeBand = ee.Image.constant(y).toFloat().rename('year');
    return eraY.resample('bilinear').add(topoCorr).rename('T').clip(roi)
    .addBands(timeBand)
    .set('year', y).set('system:time_start', s.millis());
  }));
  
  // Coleccion anual de Precipitacion
  var Pyears = ee.ImageCollection(years.map(function(y) {
    y = ee.Number(y);
    var s = ee.Date.fromYMD(y, 1, 1), e = s.advance(1, 'year');
    var chY = chirpsCol.filterDate(s, e).select('precipitation').sum()
    .setDefaultProjection(cProj);
    var ratio = chY.divide(chirps.max(1)).resample('bilinear');
    var timeBand = ee.Image.constant(y).toFloat().rename('year');
    return Pfine.multiply(ratio).rename('P').clip(roi)
    .addBands(timeBand)
    .set('year', y).set('system:time_start', s.millis());
  }));
  
  // Nombres limpios por banda: T_2001 .. T_2025 y P_2001 .. P_2025
  function bandNamesFor(prefix) {
    return years.map(function(y) {
      return ee.String(prefix).cat(ee.Number(y).toInt().format());
    });
  }
  
  // Apilado en 2 unicos objetos Multibanda (25 bandas cada uno)
  var Tstack = Tyears.select('T').toBands().rename(bandNamesFor('T_')).toFloat();
  var Pstack = Pyears.select('P').toBands().rename(bandNamesFor('P_')).toFloat();
  
  print('Bandas compiladas en Tstack:', Tstack.bandNames());
  print('Bandas compiladas en Pstack:', Pstack.bandNames());
  
  // ---------- 7. VARIABILIDAD INTERANUAL Y TENDENCIAS ----------
    var Tstd = Tyears.select('T').reduce(ee.Reducer.sampleStdDev()).rename('T_std_interanual');
  var Pstd = Pyears.select('P').reduce(ee.Reducer.sampleStdDev()).rename('P_std_interanual');
  var Pcv = Pstd.divide(Pfine.max(1)).multiply(100).rename('P_CV_pct');
  
  // Pendiente lineal temporal (cambio por decada)
  var Ttrend = Tyears.select(['year', 'T']).reduce(ee.Reducer.linearFit())
  .select('scale').multiply(10).rename('T_trend_decada'); // degC / decada
  var Ptrend = Pyears.select(['year', 'P']).reduce(ee.Reducer.linearFit())
  .select('scale').multiply(10).rename('P_trend_decada'); // mm / decada
  
  var VarImg = Tstd.addBands(Pstd).addBands(Pcv).addBands(Ttrend).addBands(Ptrend).toFloat();
  
  // ---------- 8. MODELO DE PROBABILIDAD DE ESTRES HIDRICO ----------
    var aridityDeMartonne = Pfine.divide(Tfine.add(10)).rename('DeMartonne_Index');
  
  function normalizeBand(img, name) {
    var pct = img.reduceRegion({
      reducer: ee.Reducer.percentile([2, 98]),
      geometry: roi, scale: SCALE_STATS, maxPixels: 1e9, bestEffort: true
    });
    var minVal = ee.Image.constant(pct.get(name + '_p2'));
    var maxVal = ee.Image.constant(pct.get(name + '_p98'));
    return img.subtract(minVal).divide(maxVal.subtract(minVal)).clamp(0, 1);
  }
  
  var riskAridity = ee.Image(1).subtract(normalizeBand(aridityDeMartonne, 'DeMartonne_Index'));
  var riskVariability = normalizeBand(Pcv, 'P_CV_pct');
  var riskSoilMoisture = ee.Image(1).subtract(normalizeBand(ndmi.clip(roi), 'ndmi'));
  var riskSlope = normalizeBand(slope.clip(roi), 'slope');
  
  var waterStressProb = riskAridity.multiply(0.35)
  .add(riskSoilMoisture.multiply(0.30))
  .add(riskVariability.multiply(0.20))
  .add(riskSlope.multiply(0.15))
  .multiply(100)
  .rename('Prob_Estres_Hidrico_pct')
  .toFloat();
  
  var waterStressClass = ee.Image(1)
  .where(waterStressProb.gte(35), 2)
  .where(waterStressProb.gte(55), 3)
  .where(waterStressProb.gte(70), 4)
  .rename('Clase_Estres_Hidrico')
  .clip(roi)
  .toFloat();
  
  var StressImg = waterStressProb
  .addBands(waterStressClass)
  .addBands(aridityDeMartonne.toFloat())
  .addBands(ndmi.clip(roi).toFloat());
  
  // ---------- 9. ESTADISTICOS PROVINCIALES ANUALES ----------
    function statsPorAnio(col, bandName) {
      var red = ee.Reducer.mean()
      .combine(ee.Reducer.min(), '', true)
      .combine(ee.Reducer.max(), '', true)
      .combine(ee.Reducer.stdDev(), '', true);
      return ee.FeatureCollection(col.select(bandName).map(function(img) {
        var r = img.reduceRegion({reducer: red, geometry: roi, scale: SCALE_STATS,
          maxPixels: 1e10, bestEffort: true});
        return ee.Feature(null, r).set('anio', img.get('year'));
      }));
    }
  var Tstats = statsPorAnio(Tyears, 'T');
  var Pstats = statsPorAnio(Pyears, 'P');
  
  print(ui.Chart.image.series(Tyears.select('T'), roi, ee.Reducer.mean(), 500)
        .setOptions({title: 'Serie Anual de Temperatura Media en Anta (C)', trendlines: {0: {color: 'red'}}, legend: {position: 'none'}}));
  print(ui.Chart.image.series(Pyears.select('P'), roi, ee.Reducer.mean(), 500)
        .setOptions({title: 'Serie Anual de Precipitacion en Anta (mm)', trendlines: {0: {color: 'blue'}}, legend: {position: 'none'}}));
  
  // ---------- 10. VISUALIZACION EN EL MAPA ----------
    var visT = {min: 4, max: 18, palette: ['#313695','#74add1','#ffffbf','#f46d43','#a50026']};
  var visP = {min: 500, max: 1100, palette: ['#ffffe5','#9ecae1','#3182bd','#08306b']};
  var visStress = {min: 20, max: 80, palette: ['#2b83ba','#abdda4','#ffffbf','#fdae61','#d7191c']};
  
  Map.addLayer(Tfine, visT, 'T Media ' + PERIODO + ' (C)');
  Map.addLayer(Pfine, visP, 'P Media ' + PERIODO + ' (mm)');
  Map.addLayer(waterStressProb, visStress, 'Indice relativo WSI (0-100)');
  Map.addLayer(geometry.style({color: 'black', fillColor: '00000000', width: 2}), {}, 'Provincia de Anta');
  
  // ---------- 11. EXPORTACION OPTIMIZADA (SIN TAREAS INDIVIDUALES POR ANIO) ----------
    // 1. LOS DOS ARCHIVOS MULTIBANDA ANUALES PRINCIPALES (25 bandas cada uno)
  Export.image.toDrive({
    image: Tstack,
    description: 'T_anual_Multibanda_Anta_' + PERIODO,
    folder: FOLDER_OUT,
    region: roi, scale: SCALE_OUT, crs: CRS_OUT, maxPixels: 1e10
  });
  
  Export.image.toDrive({
    image: Pstack,
    description: 'P_anual_Multibanda_Anta_' + PERIODO,
    folder: FOLDER_OUT,
    region: roi, scale: SCALE_OUT, crs: CRS_OUT, maxPixels: 1e10
  });
  
  // 2. Capas sinteticas (Climatologia media, Variabilidad/Tendencias y Estres Hidrico)
  Export.image.toDrive({
    image: Tfine.addBands(Pfine).toFloat(),
    description: 'Climatologia_Media_TP_Anta_' + PERIODO,
    folder: FOLDER_OUT,
    region: roi, scale: SCALE_OUT, crs: CRS_OUT, maxPixels: 1e10
  });
  
  Export.image.toDrive({
    image: VarImg,
    description: 'Variabilidad_y_Tendencias_Anta_' + PERIODO,
    folder: FOLDER_OUT,
    region: roi, scale: SCALE_OUT, crs: CRS_OUT, maxPixels: 1e10
  });
  
  Export.image.toDrive({
    image: StressImg,
    description: 'Estres_Hidrico_Anta_' + PERIODO,
    folder: FOLDER_OUT,
    region: roi, scale: SCALE_OUT, crs: CRS_OUT, maxPixels: 1e10
  });

  // DEM del mismo flujo para auditar altitud de estaciones y cualquier
  // correccion termica futura. Exportarlo no modifica las capas climaticas.
  Export.image.toDrive({
    image: dem.clip(roi).toFloat(),
    description: 'DEM_SRTM_30m_Anta',
    folder: FOLDER_OUT,
    region: roi, scale: SCALE_OUT, crs: CRS_OUT, maxPixels: 1e10
  });
  
  // 3. Tablas CSV con estadisticos anuales
  Export.table.toDrive({
    collection: Tstats,
    description: 'T_estadisticos_anuales_Anta_' + PERIODO,
    folder: FOLDER_OUT, fileFormat: 'CSV',
    selectors: ['anio', 'T_mean', 'T_min', 'T_max', 'T_stdDev']
  });
  
  Export.table.toDrive({
    collection: Pstats,
    description: 'P_estadisticos_anuales_Anta_' + PERIODO,
    folder: FOLDER_OUT, fileFormat: 'CSV',
    selectors: ['anio', 'P_mean', 'P_min', 'P_max', 'P_stdDev']
  });
