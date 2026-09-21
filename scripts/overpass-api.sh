A la web:
https://overpass-turbo.eu/#

Provar d'executar aqeusta instrucció:

[out:xml][timeout:900][maxsize:1073741824];

// Definim les àrees que volem buscar dins del Bounding Box
(
  // 1. Camins, corriols, pistes forestals i carrers/carreteres connectades
  way["highway"~"path|footway|track|steps|residential|unclassified|tertiary|secondary|primary"]({{bbox}});
  
  // 2. Pics, muntanyes i colls
  node["natural"~"peak|saddle"]({{bbox}});
  
  // 3. Fonts i punts d'aigua natural
  node["natural"="spring"]({{bbox}});
  node["amenity"="drinking_water"]({{bbox}});
  
  // 4. Refugis (guardats i lliures), albergs i zones d'acampada
  node["tourism"~"alpine_hut|wilderness_hut|hostel|camp_site"]({{bbox}});
  way["tourism"~"alpine_hut|wilderness_hut|hostel|camp_site"]({{bbox}});
  
  // 5. Rutes de senderisme senyalitzades (GR, PR, SL, etc.)
  relation["route"="hiking"]({{bbox}});
);

// Recopilem la geometria completa de les vies i relacions de forma eficient
(._;>;);

// Retornem les dades amb les metadades (autor, versió, data) per si vols editar-ho
out meta;
