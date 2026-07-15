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

        # Projecció de map-matching del punt mig per projectar sobre la guia de forma ràpida
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
    print("🛰️  MOTOR D'AUDITORIA GEOMÈTRICA SENDA - FILTRE ADAPTATIU PRO")
    print("===============================================================")

    track_guia = parse_gpx("track_guia.gpx")
    track_gravat = parse_gpx("track_gravat.gpx")

    if not track_guia or not track_gravat:
        return

    print(f"📊 Fitxers carregats: Guia ({len(track_guia)} pts) | Gravat ({len(track_gravat)} pts)")

    segment_history = []
    total_projected_step = 0.0
    last_projected_idx = None

    fail_near = 0
    fail_heading = 0
    fail_trend = 0
    punts_totals = 0
    punts_on_track = 0

    for i in range(1, len(track_gravat)):
        p_prev = track_gravat[i-1]
        p_curr = track_gravat[i]
        punts_totals += 1

        # 1. Map-matching geomètric bàsic sobre la línia de la guia
        seg_idx, dist_lateral, track_bearing = project_on_track_segment(p_curr, track_guia)
        cond_near = dist_lateral < NEAR_THRESHOLD

        if not cond_near:
            fail_near += 1
            continue  # 🌟 LA MILLORA: Si estàs lluny de la línia, ignorem aquest punt perquè no alteri la telemetria!

        punts_on_track += 1

        # 2. Rumb de desplaçament real del mòbil (userBearing)
        user_bearing = calculate_bearing(p_prev[0], p_prev[1], p_curr[0], p_curr[1])

        # 3. Buffer d'índexs
        segment_history.append(seg_idx)
        if len(segment_history) > 10:
            segment_history.pop(0)

        # 4. Sumar progressió acumulada sobre el track (projectedStep)
        if last_projected_idx is not None:
            p_guia_prev = track_guia[last_projected_idx]
            p_guia_curr = track_guia[seg_idx]
            step = haversine(p_guia_prev[0], p_guia_prev[1], p_guia_curr[0], p_guia_curr[1])
            if 0 < step < 50:
                total_projected_step += step
        last_projected_idx = seg_idx

        # 5. Diferència angular de vectors
        heading_diff = heading_difference(track_bearing, user_bearing)
        cond_heading = heading_diff > REVERSE_MIN_ANGLE
        cond_trend = check_reverse_trend(segment_history)

        if not cond_heading: fail_heading += 1
        if not cond_trend: fail_trend += 1

    # ─── INFORME FINAL DE DIAGNÒSTIC REFARET ───
    print("---------------------------------------------------------------")
    print("🚨 INFORME DE DIAGNÒSTIC SENSE REPTES DE LONGITUD:")
    print("---------------------------------------------------------------")
    print(f"• Punts totals del teu fitxer gravat: {punts_totals}")
    print(f"• Punts realment propers al track guia (On-Track): {punts_on_track}")
    print(f"• Punts descartats per estar fora del radi o viatges extres: {fail_near}")

    if punts_on_track == 0:
        print("\n❌ VERDICTE CRÍTIC: El teu track gravat està completament separat de la línia guia. "
              "L'usuari mai ha arribat a trepitjar el camí a menys de 15 metres, per tant el motor mai s'ha pogut engegar.")
        print("===============================================================")
        return

    print(f"• Distància total sumada seguint la traça: {total_projected_step:.1f} metres.")

    print(f"\nAnàlisi estricte del tram On-Track (Sobre {punts_on_track} posicions avaluades):")
    print(f"• Caminant mirant a favor del track (Falla headingDiff > 140°): {fail_heading} vegades.")
    print(f"• Els segments NO han decrementat cronològicament (Falla hasReverseSegmentTrend): {fail_trend} vegades.")

    print("\n💡 VERDICTE FINAL DE L'AUDITORIA:")
    if fail_trend == punts_on_track:
        print("▶️ CODI DE PUNT CEC: Els segments del teu track guia estan excessivament junts o el tram "
              "en sentit invers va ser massa curt. L'algorisme de map-matching t'ha projectat gairebé sempre "
              "sobre el mateix número de línia, evitant que la llista decrementés.")
    elif fail_heading == punts_on_track:
        print("▶️ CODI DE PUNT CEC: El canvi de rumb angular mai ha superat els 140 graus. Això passa "
              "si el fitxer enregistrat és una simulació estàtica de laboratori sense canvis reals a la brúixola, "
              "o si vau caminar fent ziga-zagues molt obertes.")
    else:
        print("▶️ CODI DE PUNT CEC: La telemetria geomètrica és correcta! Si l'app no es va immutar, "
              "revisa si la distància total recorreguda enrere ({:.1f}m) ha superat el llindar de seguretat "
              "exigit a la teva variable de Flutter 'TrackThresholds.reverseMinDistance'.".format(total_projected_step))
    print("===============================================================")

if __name__ == "__main__":
    executa_auditoria()
