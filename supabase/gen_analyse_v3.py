#!/usr/bin/env python3
"""Synthèses V3 (docs/V3-synthese-entree.md) -> SQL ppi_v3_liste + ppi_v3_analyse (docs/V3-donnees-page2.md).

Usage : python3 gen_analyse_v3.py synthese_NC.xlsx synthese_EL.xlsx correspondance_licences.csv sortie.sql [saison]
        [--double=LICENCE,LICENCE]   athlètes en double projet natation course + eau libre
Aucune donnée nominative dans ce script : tout vient des fichiers passés en argument.
"""
import csv, json, re, sys, unicodedata
from collections import OrderedDict, defaultdict
import openpyxl

SAISON = '2025-2026'

EP_NC = {'Nage libre': 'Libre', '4 nages': '4 Nages'}
MOIS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
        'septembre', 'octobre', 'novembre', 'décembre']


def norm(s):
    s = unicodedata.normalize('NFD', str(s or '')).encode('ascii', 'ignore').decode().upper()
    return re.sub(r'[^A-Z]', '', s)


def ep_nc(e):
    for a, b in EP_NC.items():
        e = e.replace(a, b)
    return e


def sec(t):
    if t is None or t == '':
        return None
    p = str(t).split(':')
    v = 0.0
    for x in p:
        v = v * 60 + float(x)
    return v


def ecart(a, b, unite=''):
    if a is None or b is None:
        return ''
    d = round(a - b, 2)
    if d == 0:
        return '0.00' + unite
    return ('+' if d > 0 else '−') + f'{abs(d):.2f}' + unite


def num(v):
    if v is None or v == '' or v == 'non publié':
        return None
    return float(v)


def txt(v):
    if v is None:
        return ''
    if isinstance(v, float):
        return f'{v:g}'
    return str(v)


def date_fr(iso_list):
    ds = [d.strip() for d in str(iso_list or '').split(',') if d.strip()]
    if not ds:
        return ''
    parts = [(int(d[8:10]), int(d[5:7]), d[:4]) for d in ds]
    out, i = [], 0
    while i < len(parts):
        j = i
        while j + 1 < len(parts) and parts[j + 1][1:] == parts[i][1:]:
            j += 1
        jours = ['1er' if p[0] == 1 else str(p[0]) for p in parts[i:j + 1]]
        txtj = jours[0] if len(jours) == 1 else ', '.join(jours[:-1]) + ' et ' + jours[-1]
        out.append(f'{txtj} {MOIS[parts[i][1] - 1]}')
        i = j + 1
    return ', '.join(out) + ' ' + parts[-1][2]


def place_fr(p):
    return '' if p is None else ('1er' if int(p) == 1 else f'{int(p)}e')


def feuille(wb, nom):
    rows = list(wb[nom].iter_rows(values_only=True))
    h = rows[0]
    return [dict(zip(h, r)) for r in rows[1:] if any(c is not None for c in r)]


def nom_ligne(r):
    return f"{r['nageur']} — {r['competition']}"


# ---------------------------------------------------------------- natation course
def analyse_nc(ath, wb, sources):
    res, p50, ph = feuille(wb, 'resultats'), feuille(wb, 'par50'), feuille(wb, 'phases')
    nom = f"{ath['nom']} {ath['prenom']}"
    nk = norm(nom)
    mine = [r for r in res if r['type_ligne'] == 'athlete' and norm(r['nageur']) == nk]
    blocs, epl, res_s, res_r, epr_s, kpi = [], [], [], [], [], []

    def refs_of(rows, ep, sexe):
        seen, out = set(), []
        for r in rows:
            if r['type_ligne'] == 'reference' and r['epreuve'] == ep and r['sexe'] == sexe:
                k = tuple(sorted((a, str(b)) for a, b in r.items() if a != 'licence'))
                if k not in seen:
                    seen.add(k)
                    out.append(r)
        return out

    for a in mine:
        ep, sexe = a['epreuve'], a['sexe']
        epl.append(ep_nc(ep))
        refs = sorted(refs_of(res, ep, sexe), key=lambda r: (r['rang_reference'], sec(r['temps'])))
        if len(mine) > 1:
            blocs.append({'type': 'epreuve', 'titre': ep_nc(ep)})
        t1 = sec(refs[0]['temps']) if refs else None
        t3 = max((sec(r['temps']) for r in refs if r['rang_reference'] == 3), default=None)
        lignes = []
        for r in [a] + refs:
            t = sec(r['temps'])
            e1 = '—' if r is not a and r['rang_reference'] == 1 else ecart(t, t1)
            e3 = '—' if r is not a and r['rang_reference'] == 3 else ecart(t, t3)
            lab = nom_ligne(r) + (f", {str(r['tour']).lower()}" if r['tour'] else '')
            lignes.append([lab, txt(r['place']), txt(r['temps']), e1, e3])
        blocs.append({'type': 'tableau', 'titre': f'1. Résultat — {ep_nc(ep)}',
                      'colonnes': ['Nageur', 'Place dans sa course', 'Temps', 'Écart au 1er performer', 'Écart au 3e performer'],
                      'lignes': lignes, 'athlete': [0],
                      'note': 'Référence : les 3 meilleurs performers des saisons 2025 et 2026 dans la base Espadon '
                              '(meilleur temps de chaque nageur, bassin de 50 m).'})
        pl_t = (place_fr(a['place']) + ' · ' if a['place'] else '') + str(a['temps'])
        epr_s.append(f"{ep_nc(ep)} ({str(a['tour'] or '').lower()})")
        if len(kpi) < 3:  # règle validée le 2026-11-26 : 3 premières épreuves, place · temps (écart 1er / 3e)
            kpi.append([f"{ep_nc(ep)} · {a['competition']}",
                        f"{pl_t} ({lignes[0][3]} / {lignes[0][4]} s)"])
        res_s.append(f"{ep_nc(ep)} : {pl_t}")
        res_r.append(f"{ep_nc(ep)} : " + ' · '.join(f"{r['nageur']} {r['temps']}" for r in refs))

        series_rows = [a] + refs
        key = lambda r: norm(r['nageur']) + '|' + str(r['competition'])

        # par 50 m
        P = defaultdict(list)
        for r in p50:
            if r['epreuve'] == ep and r['sexe'] == sexe and (
                    (r['type_ligne'] == 'athlete' and norm(r['nageur']) == nk) or r['type_ligne'] == 'reference'):
                lst = P[(r['type_ligne'], key(r))]
                if r['segment'] not in [x['segment'] for x in lst]:
                    lst.append(r)
        a50 = P.get(('athlete', key(a)), [])
        if a50:
            dist = int(re.match(r'\d+', ep).group())
            if dist == 50:
                lignes = []
                for r in series_rows:
                    s = P.get((r['type_ligne'], key(r)), [])
                    if s:
                        s = s[0]
                        lignes.append([nom_ligne(r), txt(s['passage']), txt(r['reaction']), txt(s['frequence_c_min']),
                                       txt(s['coups_bras']), txt(s['dpc_m_cycle'])])
                blocs.append({'type': 'tableau', 'titre': '2. Course (0-50 m)',
                              'colonnes': ['Nageur', 'Temps', 'Réaction', 'Fréquence (c/min)', 'Coups de bras', 'DPC (m/cycle)'],
                              'lignes': lignes, 'athlete': [0]})
            elif dist >= 400:
                # Demi-fond (décision du 2026-11-27) : nageurs côte à côte, un tableau des passages
                # et trois courbes (temps par 50 m, fréquence, DPC) au lieu d'un long tableau.
                segs = [x['segment'] for x in a50]
                par = [(r, {x['segment']: x for x in P.get((r['type_ligne'], key(r)), [])}) for r in series_rows]
                par = [(r, d) for r, d in par if d]
                apass = {x['segment']: sec(x['passage']) for x in a50}
                lignes = []
                for sg in segs:
                    l = [sg]
                    for r, d in par:
                        x = d.get(sg)
                        if not x:
                            l.append('—')
                        elif r is a:
                            l.append(txt(x['passage']))
                        else:
                            l.append(f"{txt(x['passage'])} ({ecart(apass.get(sg), sec(x['passage']))})")
                    lignes.append(l)
                blocs.append({'type': 'tableau', 'titre': '2. Passages par 50 m',
                              'colonnes': ['Segment'] + [f"{r['nageur']}{' (athlète)' if r is a else ''}" for r, d in par],
                              'lignes': lignes,
                              'note': 'Passage cumulé ; entre parenthèses, écart de l’athlète au nageur de la colonne '
                                      '(+ = athlète plus lent). Nageurs : ' + ' · '.join(nom_ligne(r) for r, d in par) + '.'})
                axe = [sg.split('-')[-1].replace(' m', '') for sg in segs]
                for titre, champ, unite in [('Temps par 50 m', 'temps_segment', 's'), ('Fréquence', 'frequence_c_min', 'c/min'),
                                            ('Distance par cycle', 'dpc_m_cycle', 'm/cycle')]:
                    blocs.append({'type': 'courbe', 'titre': f'2. {titre} ({unite})', 'axe': axe, 'etiquette_axe': 'm',
                                  'inverse': False,
                                  'note': {'temps_segment': 'Temps de chaque 50 m : plus haut = plus lent.',
                                           'frequence_c_min': 'Cycles de bras par minute.',
                                           'dpc_m_cycle': 'Distance parcourue par cycle de bras : plus haut = plus ample.'}[champ],
                                  'series': [{'nom': nom_ligne(r), 'valeurs': [num(sec(d[sg][champ]) if champ == 'temps_segment'
                                                                                 and d.get(sg) else (d[sg][champ] if d.get(sg) else None))
                                                                             for sg in segs]} for r, d in par]})
            else:
                apass = {x['segment']: sec(x['passage']) for x in a50}
                lignes, ath_idx = [], []
                for r in series_rows:
                    for s in P.get((r['type_ligne'], key(r)), []):
                        if r is a:
                            ath_idx.append(len(lignes))
                        ec = '—' if r is a else ecart(apass.get(s['segment']), sec(s['passage']))
                        lignes.append([nom_ligne(r), s['segment'], txt(s['passage']), txt(s['temps_segment']), ec,
                                       txt(s['frequence_c_min']), txt(s['coups_bras']), txt(s['dpc_m_cycle'])])
                blocs.append({'type': 'tableau', 'titre': '2. Par 50 m',
                              'colonnes': ['Nageur', 'Segment', 'Passage', 'Temps segment', 'Écart cumulé de l’athlète',
                                           'Fréquence (c/min)', 'Coups de bras', 'DPC (m/cycle)'],
                              'lignes': lignes, 'athlete': ath_idx,
                              'note': 'Écart cumulé de l’athlète : écart de l’athlète au nageur de la ligne, au passage '
                                      '(+ = athlète plus lent).'})

        # phases
        Q = defaultdict(dict)
        for r in ph:
            if r['epreuve'] == ep and r['sexe'] == sexe and (
                    (r['type_ligne'] == 'athlete' and norm(r['nageur']) == nk) or r['type_ligne'] == 'reference'):
                Q[(r['type_ligne'], key(r))].setdefault((str(r['longueur']), r['phase']), (r['valeur'], r['unite']))
        qa = Q.get(('athlete', key(a)), {})
        if qa:
            ordre = []
            for k in qa:
                if k[0] not in ordre:
                    ordre.append(k[0])
            groupes = []
            for lg in ordre:
                phases_lg = [k[1] for k in qa if k[0] == lg]
                titre = 'Moyennes sur les virages' if lg == 'moyenne virages' else \
                    f'Longueur {lg} ({(int(lg) - 1) * 50}-{int(lg) * 50} m)'
                pl = []
                for phn in phases_lg:
                    unite = qa[(lg, phn)][1]
                    vals = [num(Q.get((r['type_ligne'], key(r)), {}).get((lg, phn), (None, None))[0]) for r in series_rows]
                    d = {'nom': phn, 'unite': unite, 'valeurs': vals}
                    if unite == 'm':
                        d['plus_haut_meilleur'] = True
                    pl.append(d)
                groupes.append({'titre': titre, 'phases': pl})
            blocs.append({'type': 'barres',
                          'titre': '3. Phases — moyennes sur les virages' if ordre == ['moyenne virages']
                          else '3. Phases, longueur par longueur',
                          'series': [f"{r['nageur']} — {r['competition']}" for r in series_rows],
                          'groupes': groupes,
                          'note': 'Temps en secondes, coulées en mètres. Valeur à droite du titre = écart de l’athlète '
                                  'au meilleur des performers de référence. Départ réaction comprise.'})
        if not a50 and not qa:
            blocs.append({'type': 'texte', 'titre': '2. Analyse de course',
                          'texte': 'Pas d’analyse de course (passages, phases) dans la synthèse pour cette épreuve.'})

    eps = ', '.join(epl)
    donnees = OrderedDict([
        ('epreuves', eps), ('epreuves_liste', epl),
        ('saison', {'comp': ath['competition_reference'], 'date': ath['dates'] or '',
                    'epr': ' · '.join(epr_s), 'res': ' — '.join(res_s)}),
        ('reference', {'tag': 'Référence : top 3 des performers 2025-2026',
                       'tagd': 'meilleur temps de chaque nageur, base Espadon',
                       'comp': 'Top 3 des performers — saisons 2025-2026', 'date': 'meilleur temps de chaque nageur',
                       'epr': eps + ' · bassin de 50 m', 'res': ' — '.join(res_r)}),
        ('sources', sources), ('kpi', kpi), ('blocs', blocs)])
    return donnees


# ---------------------------------------------------------------- eau libre
def analyse_el(ath, wb, sources):
    res, tours, bas = feuille(wb, 'resultats'), feuille(wb, 'tours'), feuille(wb, 'bassin')
    lic = str(ath['licence'])
    sexe = ath['sexe']
    mine = [r for r in res if r['type_ligne'] == 'athlete' and str(r['licence']) == lic]
    eps = list(OrderedDict.fromkeys(r['epreuve'] for r in mine))
    blocs = []
    ref_comp = ath['competition_reference']

    # Point aberrant : position supérieure au nombre de classés de la course -> passage retiré (« non publié »)
    nbc = {(r['nageur'], r['epreuve'], r['competition']): r['nb_classes'] for r in res}
    retires = defaultdict(list)
    tours = [dict(t) for t in tours]
    for t in tours:
        n = nbc.get((t['nageur'], t['epreuve'], t['competition']))
        p = num(t['position']) if isinstance(t['position'], (int, float)) or str(t['position']).isdigit() else None
        if n and p and p > n:
            retires[(t['epreuve'], t['competition'], t['sexe'])].append(f"{t['nageur']} au passage {t['passage']} "
                                                             f"(position {int(p)} pour {n} classés)")
            for c in ('position', 'temps_passage', 'ecart_leader_s', 'coups_bras_min'):
                t[c] = 'non publié'

    def note_retires(ep, comp, base):
        R = retires.get((ep, comp, sexe))
        return base + (' Passage retiré, incohérent dans la source : ' + ' ; '.join(R) + '.' if R else '')

    def tours_of(nageur_ok, ep, comp):
        return [t for t in tours if nageur_ok(t) and t['epreuve'] == ep and t['competition'] == comp]

    def top3(r, complet=False):
        """Top 3 de la course de l'athlète (même épreuve, même compétition, même sexe) ; décision du 2026-11-27."""
        cand = [x for x in res if x['type_ligne'] == 'reference' and x['epreuve'] == r['epreuve']
                and x['competition'] == r['competition'] and x['sexe'] in (sexe, 'X')]
        groupes = []  # plusieurs manches (KO) : un groupe par série de rangs 1, 2, 3
        for x in cand:
            if not groupes or x['rang_reference'] <= groupes[-1][-1]['rang_reference']:
                groupes.append([])
            groupes[-1].append(x)
        if len(groupes) > 1:
            groupes = [g for g in groupes if sec(g[0]['temps']) == sec(r['temps_vainqueur'])]
        if len(groupes) != 1:
            return []
        g = sorted(groupes[0], key=lambda x: x['rang_reference'])
        return g if complet else [x for x in g if str(x['licence'] or '') != lic]

    def ec_v(r):
        return '—' if not r['ecart_vainqueur_s'] else f"+{r['ecart_vainqueur_s']:.2f} s (+{r['ecart_vainqueur_pct']:.2f} %)"

    def pos_courbe(series, comp):
        axe = list(OrderedDict.fromkeys(str(t['passage']) for _, T in series for t in T))
        return axe, [{'nom': nom, 'valeurs': [next((num(t['position']) for t in T if str(t['passage']) == x
                                                    and str(t['position']).replace('.', '').isdigit()), None)
                                              for x in axe]} for nom, T in series]

    n = 1
    for ep in eps:
        if len(eps) > 1:
            blocs.append({'type': 'epreuve', 'titre': ep})
        rows = [r for r in mine if r['epreuve'] == ep]
        n = 1
        for r in rows:
            comp = r['competition']
            refs = top3(r)
            lignes = []
            for x in [r] + refs:
                pl = f"{x['place']} / {x['nb_classes']}" if x['nb_classes'] else txt(x['place'])
                lignes.append([x['nageur'], pl, txt(x['temps']), ec_v(x)])
            blocs.append({'type': 'tableau', 'titre': f"{n}. Résultat — {ep} — {comp}",
                          'colonnes': ['Nageur', 'Place', 'Temps', 'Écart au vainqueur'],
                          'lignes': lignes, 'athlete': [0],
                          'note': f"Référence : les 3 premiers de la course ({comp})."
                                  + ('' if refs else ' Top 3 non fourni dans la synthèse.')})
            n += 1
            series = [(f"{r['nageur']} (athlète)", tours_of(lambda t: str(t['licence']) == lic and t['type_ligne'] == 'athlete', ep, comp))]
            series += [(f"{p['rang_reference']}. {p['nageur']}",
                        tours_of(lambda t, p=p: t['type_ligne'] == 'reference' and t['nageur'] == p['nageur'], ep, comp))
                       for p in refs]
            series = [(a, T) for a, T in series if T]
            if series and series[0][0].endswith('(athlète)'):
                axe, ser = pos_courbe(series, comp)
                if len(axe) > 1:
                    blocs.append({'type': 'courbe', 'titre': f"{n}. Position tour par tour — {comp}",
                                  'axe': axe, 'etiquette_axe': 'passage', 'series': ser,
                                  'note': note_retires(ep, comp, 'Position : 1 en haut. Athlète et 3 premiers de la course. '
                                                                 'Trait pointillé = passage non publié.')})
                blocs.append({'type': 'tableau', 'titre': f"{n}. Tour par tour — {comp}",
                              'colonnes': ['Nageur', 'Passage', 'Position', 'Temps de passage', 'Écart au leader (s)',
                                           'Coups de bras/min'],
                              'lignes': [[a, str(t['passage']), txt(t['position']), txt(t['temps_passage']),
                                          txt(t['ecart_leader_s']), txt(t['coups_bras_min'])] for a, T in series for t in T],
                              'athlete': list(range(len(series[0][1]))),
                              'note': note_retires(ep, comp, 'Passage non publié : « non publié ».')})
                n += 1

    ref_rows = [r for r in mine if r['competition'] and ref_comp and r['competition'].split()[0] in ('CE', 'CEJ')
                and r['competition'].split()[-1] in ref_comp]
    main_r = next((r for r in ref_rows if r['epreuve'] == '10km'), ref_rows[0] if ref_rows else None)
    podium = top3(main_r) if main_r else []
    podium_complet = top3(main_r, True) if main_r else []

    # niveau en bassin : athlète et 3 premiers de sa course principale de référence
    B = [b for b in bas if b['type_ligne'] == 'athlete' and str(b['licence']) == lic]
    if B and main_r:
        BR = [b for b in bas if b['type_ligne'] == 'reference' and b['sexe'] == sexe
              and b['epreuve'] == main_r['epreuve'] and b['competition'] == main_r['competition']]
        cell = lambda b: f"{b['temps']} ({str(b['date'])[:7]})" if b and b['temps'] else '—'
        lignes = []
        for e in ['400 NL', '800 NL', '1500 NL']:
            a = next((b for b in B if b['epreuve_bassin'] == e), None)
            pr = [next((b for b in BR if b['epreuve_bassin'] == e and b['nageur'] == p['nageur']), None) for p in podium]
            vals = [sec(b['temps']) for b in pr if b and b['temps']]
            moy = sum(vals) / len(vals) if vals else None
            if moy is not None:
                m, s_ = divmod(moy, 60)
                moy_txt = f"{int(m)}:{s_:05.2f} ({len(vals)} nageur{'s' if len(vals) > 1 else ''})"
            else:
                moy_txt = '—'
            ta = sec(a['temps']) if a and a['temps'] else None
            ecp = '—' if ta is None or moy is None else ('+' if ta >= moy else '−') + f'{abs(ta - moy) / moy * 100:.2f} %'
            lignes.append([e, cell(a)] + [cell(b) for b in pr] + [moy_txt, ecp])
        fa = B[0]
        if len(eps) > 1:
            blocs.append({'type': 'epreuve', 'titre': 'Niveau en bassin'})
        blocs.append({'type': 'tableau',
                      'titre': f"Niveau en bassin (50 m) — athlète et 3 premiers du {main_r['epreuve']} — {main_r['competition']}",
                      'colonnes': ['Épreuve', ath['nom']] + [p['nageur'] for p in podium] +
                                  ['Moyenne du top 3 (hors athlète)', 'Écart de l’athlète à la moyenne'],
                      'lignes': lignes,
                      'note': f"Meilleurs temps sur les 24 mois précédant la course (du {fa['fenetre_debut']} au {fa['fenetre_fin']})."
                              + ('' if BR else ' Temps des 3 premiers non fournis dans la synthèse.')})

    kpi = []  # règle validée le 2026-11-26 ; écart au 3e de la course (décision du 2026-11-27)
    if main_r:
        nb = f" / {main_r['nb_classes']}" if main_r['nb_classes'] else ''
        kpi.append([f"{main_r['epreuve']} · {main_r['competition']}", f"{place_fr(main_r['place'])}{nb} · {main_r['temps']}"])
        kpi.append(['Écart au vainqueur', ec_v(main_r) if main_r['ecart_vainqueur_s'] else 'vainqueur'])
        if len(podium_complet) >= 3 and podium_complet[-1]['ecart_vainqueur_pct'] is not None:
            kpi.append([f"3e du {main_r['epreuve']}", f"+{podium_complet[-1]['ecart_vainqueur_pct']:.2f} % du vainqueur"])
    donnees = OrderedDict([
        ('epreuves', ', '.join(eps)), ('epreuves_liste', eps),
        ('saison', {'comp': ref_comp, 'date': date_fr(ath['dates']),
                    'epr': ', '.join(r['epreuve'] for r in ref_rows),
                    'res': ' — '.join(f"{r['epreuve']} : {place_fr(r['place'])}"
                                      f"{' / ' + str(r['nb_classes']) if r['nb_classes'] else ''} · {r['temps']}"
                                      for r in ref_rows)}),
        ('reference', {'tag': 'Référence : top 3 de la course',
                       'tagd': ref_comp,
                       'comp': f"Top 3 — {ref_comp}",
                       'date': date_fr(main_r['date']) if main_r else '',
                       'epr': main_r['epreuve'] if main_r else '',
                       'res': ('Top 3 : ' + ' · '.join(f"{p['nageur']} {p['temps']}" for p in podium_complet)) if podium_complet
                              else 'Top 3 à venir'}),
        ('sources', sources), ('kpi', kpi), ('blocs', blocs)])
    return donnees


SOURCES_EL = ['World Aquatics', 'Omega', 'European Aquatics', 'MicroPlus', 'Extranat', 'SwimRankings']  # liste de Pierre, 2026-11-27
SOURCES_CONNUES = [('world aquatics', 'World Aquatics'), ('omega', 'Omega'), ('european aquatics', 'European Aquatics'),
                   ('microplus', 'MicroPlus'), ('extranat', 'Extranat'), ('swimrankings', 'SwimRankings'), ('espadon', 'Espadon')]


def sources_courtes(lignes, disc):
    """Une seule ligne de noms de sources (décision du 2026-11-27)."""
    if disc == 'eau-libre':
        noms = list(SOURCES_EL)
    else:
        t = ' '.join(' '.join(map(str, l)) for l in lignes).lower()
        noms = [nom for cle, nom in SOURCES_CONNUES if cle in t]
    return [['Sources', ' · '.join(noms)]]


def q(s):
    return "'" + str(s).replace("'", "''") + "'"


def avec_epreuve(d):
    """Double projet : chaque épreuve doit être ouverte par un bloc « epreuve »."""
    if d['blocs'] and d['blocs'][0]['type'] != 'epreuve':
        return [{'type': 'epreuve', 'titre': d['epreuves_liste'][0]}] + d['blocs']
    return d['blocs']


def fusion(el, nc):
    """docs/V3-donnees-page2.md, section 5 bis : une seule ligne, eau libre en 1re discipline."""
    d = OrderedDict(el)
    d['epreuves'] = el['epreuves'] + ', ' + nc['epreuves']
    d['epreuves_liste'] = el['epreuves_liste'] + [e for e in nc['epreuves_liste'] if e not in el['epreuves_liste']]
    d['saison'] = dict(el['saison'], tag='Compétition de référence en eau libre')
    d['references_supplementaires'] = [{'saison': dict(nc['saison'], tag='Compétition de référence en bassin'),
                                        'reference': nc['reference']}]
    noms = el['sources'][0][1].split(' · ') + [x for x in nc['sources'][0][1].split(' · ') if x not in el['sources'][0][1]]
    d['sources'] = [['Sources', ' · '.join(noms)]]
    d['kpi'] = el['kpi'] + nc['kpi']
    d['blocs'] = avec_epreuve(el) + avec_epreuve(nc)
    d.move_to_end('blocs')
    return d


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    global SAISON
    SAISON = args[4] if len(args) > 4 else '2025-2026'
    double = set()
    for a in sys.argv[1:]:
        if a.startswith('--double='):
            double = {x.strip().upper() for x in a.split('=', 1)[1].split(',') if x.strip()}
    f_nc, f_el, f_lic, f_out = args[:4]
    lic, officiel = {}, {}
    with open(f_lic, encoding='utf-8-sig') as fh:
        for r in csv.DictReader(fh, delimiter=';'):
            if r['statut'] != 'doublon':
                l = r['licence'].replace(' ', '').upper()
                lic[(r['discipline'], norm(r['nom_liste']), norm(r['prenom_liste']))] = l
                lic.setdefault(('*', norm(r['nom_liste']), norm(r['prenom_liste'])), l)
                m = re.search(r'nom dans la source : (.+)$', r['remarque'] or '')
                if m:
                    officiel[l] = m.group(1).strip()

    ident, par_disc, notes = OrderedDict(), {'natation-bassin': {}, 'eau-libre': {}}, []
    for f, disc, fn in [(f_nc, 'natation-bassin', analyse_nc), (f_el, 'eau-libre', analyse_el)]:
        wb = openpyxl.load_workbook(f, data_only=True)
        sources = sources_courtes([[s['source'], s['ce_qui_en_est_tire']] for s in feuille(wb, 'sources')], disc)
        for a in feuille(wb, 'nageurs'):
            if a['statut'] == 'doublon':
                continue
            l = a['licence'] or lic.get((disc, norm(a['nom']), norm(a['prenom']))) \
                or lic.get(('*', norm(a['nom']), norm(a['prenom'])))
            if not l:
                notes.append(f"licence introuvable : {a['nom']} {a['prenom']}")
                continue
            l = str(l).replace(' ', '').upper()
            nom, prenom = a['nom'], a['prenom']
            if l in officiel and officiel[l].upper().startswith(nom.upper() + ' '):
                prenom = officiel[l][len(nom) + 1:]
                notes.append(f"prénom corrigé d'après le fichier des licences : {nom} {a['prenom']} -> {prenom}")
            ident.setdefault(l, [nom, prenom, disc])
            if a['statut'] == 'introuvable' or not a['competition_reference']:
                notes.append(f"pas d'analyse {disc} : {a['nom']} {a['prenom']} ({a['statut']})")
                continue
            par_disc[disc][l] = (a['competition_reference'], fn(a, wb, sources))

    liste, analyses = [], []
    for l, (nom, prenom, disc) in ident.items():
        nc, el = par_disc['natation-bassin'].get(l), par_disc['eau-libre'].get(l)
        d2 = None
        if l in double:
            disc, d2 = 'eau-libre', 'natation-bassin'
            if not (nc and el):
                notes.append(f"double projet sans analyse {'natation course' if not nc else 'eau libre'} : {nom} {prenom}")
        elif nc and el:
            notes.append(f"présent dans les deux synthèses sans --double : {nom} {prenom} (analyses fusionnées)")
            disc, d2 = 'eau-libre', 'natation-bassin'
        liste.append((l, nom, prenom, disc, d2))
        if nc and el:
            comp, d = el[0], fusion(el[1], nc[1])
        elif el or nc:
            comp, d = (el or nc)
        else:
            continue
        js = json.dumps(d, ensure_ascii=False, indent=1)
        assert '$json$' not in js
        for b in d['blocs']:
            if b['type'] == 'tableau':
                assert all(len(x) == len(b['colonnes']) for x in b['lignes']), (nom, b['titre'])
        analyses.append((l, 'eau-libre' if el else 'natation-bassin', comp, js, nom, prenom))
    for l in double - set(ident):
        notes.append(f"licence --double absente des synthèses : {l}")

    out = ['-- Questionnaire V3 : liste et données d’analyse (page 2), saison ' + SAISON,
           '-- Généré par supabase/gen_analyse_v3.py. Ne pas diffuser (données nominatives).',
           '-- Prérequis : supabase/ajout_v3_double_projet.sql (colonne discipline_2).', '', 'BEGIN;', '',
           'INSERT INTO public.ppi_v3_liste (licence, nom, prenom, discipline, discipline_2) VALUES']
    out.append(',\n'.join(f'  ({q(l)}, {q(n)}, {q(p)}, {q(d)}, {q(d2) if d2 else "NULL"})'
                           for l, n, p, d, d2 in liste))
    out += ['ON CONFLICT (licence) DO UPDATE',
            '  SET actif = true, nom = excluded.nom, prenom = excluded.prenom,',
            '      discipline = excluded.discipline, discipline_2 = excluded.discipline_2;', '']
    for l, disc, comp, js, n, p in analyses:
        out += [f'-- {n} {p}',
                'INSERT INTO public.ppi_v3_analyse (licence, saison, discipline, competition_reference, donnees)',
                f'VALUES ({q(l)}, {q(SAISON)}, {q(disc)}, {q(comp)},', '$json$', js, '$json$::jsonb)',
                'ON CONFLICT (licence, saison) DO UPDATE SET donnees = excluded.donnees,',
                '  competition_reference = excluded.competition_reference, discipline = excluded.discipline, maj_le = now();',
                '']
    out += ['COMMIT;', '', '-- Contrôle',
            'SELECT l.licence, l.nom, l.prenom, l.discipline, l.discipline_2, l.actif,',
            '       (SELECT count(*) FROM public.ppi_nageurs n',
            "         WHERE upper(replace(n.licence, ' ', '')) = l.licence) AS fiches,",
            '       (SELECT max(a.saison) FROM public.ppi_v3_analyse a WHERE a.licence = l.licence) AS saison_analyse,',
            "       (SELECT jsonb_array_length(a.donnees->'blocs') FROM public.ppi_v3_analyse a",
            f"         WHERE a.licence = l.licence AND a.saison = {q(SAISON)}) AS nb_blocs",
            'FROM public.ppi_v3_liste l',
            'WHERE l.licence IN (' + ', '.join(q(x[0]) for x in liste) + ')',
            'ORDER BY l.discipline, l.nom;', '']
    with open(f_out, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(out))
    print(f'{len(liste)} athlètes dans la liste, {len(analyses)} analyses')
    for n in notes:
        print(' -', n)


if __name__ == '__main__':
    main()
