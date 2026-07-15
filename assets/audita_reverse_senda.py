import xml.etree.ElementTree as ET
import math
import os

# ─── CONFIGURACIÓ DE LLINDARS (RÈPLICA DELS THRESHOLDS DE LA TEVA APP) ───
NEAR_THRESHOLD = 15.0       # Marge de proximitat en metres (isNear)
REVERSE_MIN_ANGLE = 140.0   # Marge angular en graus (headingDiff)

def parse_gpx(filename):
    """Llegeix les coordenades ordenades d'un fitxer GPX corporatiu."""
    if not os.path.exists(filename):
        print(f"❌ Error: No s'ha trobat el fitxer '{filename}' a la carpeta actual.")
        return []

    pts = []
    try:
        tree = ET.parse(filename)
        root = tree.getroot()
        # Escaneig de l'arbre tolerant qualsevol XML namespace actiu
        for trkpt in root.findall('.//{http://topografix.com}trkpt') or root.findall('.//trkpt'):
            lat = float(trkpt.attrib['lat'])
            lon = float(trkpt.attrib['lon'])
            pts.append((lat, lon))
    except Exception as e:
        print(f"❌ Error en processar el XML de '{filename}': {e}")
    return pts

def haversine(lat1, lon1, lat2, lon2):
    """Calculem la distància real en metres entre coordenades terrestres."""
    R = 6371000  # Radi de la Terra en metres
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def calculate_bearing(lat1, lon1, lat2, lon2):
    """Troba el rumb angular (0 a 360°) d'un segment o moviment."""
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_lambda = math.radians(lon2 - lon1)
    y = math.sin(delta_lambda) * math.cos(phi2)
    x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(delta_lambda)
    return (math.degrees(math.atan2(y, x)) + 360) % 360

def heading_difference(h1, h2):
    """Mesura la diferència angular més curta (0 a 180°) com la teva app."""
    diff = abs(h1 - h2) % 360
    return 360 - diff if diff > 180 else diff

def project_on_track_segment(user_pt, track_pts):
    """Troba l'índex del segment, la distància lateral i el rumb del track guia."""
    min_dist = float('inf')
    best_idx = 0
    best_bearing = 0.0

    for i in range(len(track_pts) - 1):
        p1 = track_pts[i]
        p2 = track_pts[i+1]

        # Mètode de map-matching del punt mig per projectar sobre la guia
        mid_lat = (p1[0] + p2[0]) / 2
        mid_lon = (p1[1] + p2[1]) / 2
        d = haversine(user_pt[0], user_pt[1], mid_lat, mid_lon)

        if d < min_dist:
            min_dist = d
            best_idx = i
            best_bearing = calculate_bearing(p1[0], p1[1], p2[0], p2[1])

    return best_idx, min_dist, best_bearing

def check_reverse_trend(segment_indices):
    """Replica exactament l'algorisme progress.isReverseSegmentProgression."""
    if len(segment_indices) < 4:
        return False
    drops = 0
    rises = 0
    for i in range(1, len(segment_indices)):
        if segment_indices[i] < segment_indices[i-1]:
            drops += 1
        elif segment_indices[i] > segment_indices[i-1]:
            rises += 1
    return drops > rises and drops >= 2

def executa_auditoria():
    print("===============================================================")
    print("🛰️  MOTOR D'AUDITORIA GEOMÈTRICA SENDA - CODI DE DIAGNÒSTIC")
    print("===============================================================")

    track_guia = parse_gpx("track_guia.gpx")
    track_gravat = parse_gpx("track_gravat.gpx")

    if not track_guia or not track_gravat:
        return

    print(f"📊 Fitxers carregats: Guia ({len(track_guia)} pts) | Gravat ({len(track_gravat)} pts)\n")

    # Variables auxiliars de mesura acumulada per a l'autòmat
    segment_history = []
    total_projected_step = 0.0
    last_projected_idx = None

    # Comptadors de fallades per a l'informe final
    fail_near = 0
    fail_heading = 0
    fail_trend = 0
    punts_analitzats = 0

    for i in range(1, len(track_gravat)):
        p_prev = track_gravat[i-1]
        p_curr = track_gravat[i]
        punts_analitzats += 1

        # 1. Rumb de desplaçament real del mòbil (userBearing)
        user_bearing = calculate_bearing(p_prev[0], p_prev[1], p_curr[0], p_curr[1])

        # 2. Map-matching geomètric sobre la línia de la guia
        seg_idx, dist_lateral, track_bearing = project_on_track_segment(p_curr, track_guia)
        segment_history.append(seg_idx)
        if len(segment_history) > 10:  # Mida de la finestra del buffer (reverseSegmentWindow)
            segment_history.pop(0)

        # 3. Sumar progressió acumulada sobre el track (projectedStep)
        if last_projected_idx is not None:
            p_guia_prev = track_guia[last_projected_idx]
            p_guia_curr = track_guia[seg_idx]
            step = haversine(p_guia_prev[0], p_guia_prev[1], p_guia_curr[0], p_guia_curr[1])
            if 0 < step < 50:
                total_projected_step += step
        last_projected_idx = seg_idx

        # 4. Diferència angular de vectors
        heading_diff = heading_difference(track_bearing, user_bearing)

        # 5. Verificacions de les teves 3 variables clau
        cond_near = dist_lateral < NEAR_THRESHOLD
        cond_heading = heading_diff > REVERSE_MIN_ANGLE
        cond_trend = check_reverse_trend(segment_history)

        if not cond_near: fail_near += 1
        if not cond_heading: fail_heading += 1
        if not cond_trend: fail_trend += 1

    # ─── INFORME FINAL DE DIAGNÒSTIC EXCLUSIU ───
    print("---------------------------------------------------------------")
    print("🚨 INFORME DE DIAGNÒSTIC DE PUNT CECS:")
    print("---------------------------------------------------------------")
    print(f"Distància total recorreguda sobre la línia: {total_projected_step:.1f} metres.")

    print(f"\nAnàlisi de talls (Sobre {punts_analitzats} posicions avaluades):")
    print(f"• Fora del radi de proximitat (Falla isNear): {fail_near} vegades.")
    print(f"• Caminant mirant a favor del track (Falla headingDiff > 140°): {fail_heading} vegades.")
    print(f"• Els segments NO han decrementat (Falla hasReverseSegmentTrend): {fail_trend} vegades.")

    print("\n💡 VERDICTE DE L'AUDITORIA:")
    if fail_trend == punts_analitzats:
        print("▶️ MOTIU PRINCIPAL: Els punts del teu track guia estan massa junts o el tram va ser "
              "massa curt. L'algorisme de map-matching t'ha projectat gairebé sempre sobre el mateix segment, "
              "provocant que la llista d'índexs fos plana (ex: [12, 12, 12]) i invalidant la tendència.")
    elif fail_heading == punts_analitzats:
        print("▶️ MOTIU PRINCIPAL: La diferència angular mai ha superat els 140 graus. Això passa "
              "si el fitxer enregistrat conté trossos on l'usuari feia ziga-zagues o si no hi havia moviment "
              "real lineal de brúixola en el fitxer .gpx gravat.")
    elif fail_near > (punts_analitzats * 0.5):
        print("▶️ MOTIU PRINCIPAL: T'has separat massa de la línia guia (més de 15 metres). "
              "L'autòmat ha passat a mode 'isFar/offTrack', desconnectant el motor de detecció inversa.")
    else:
        print("▶️ MOTIU PRINCIPAL: El camí ha sumat menys metres consecutius que el límit mínim definit a "
              "TrackThresholds.reverseMinDistance. Revisa si vas apagar i encendre la navegació o si hi ha salts de GPS.")
    print("===============================================================")

if __name__ == "__main__":
    executa_auditoria()
