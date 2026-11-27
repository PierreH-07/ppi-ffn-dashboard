#!/usr/bin/env python3
"""Ajoute un fichier d'analyses complémentaires (feuilles resultats, par50, phases, sources ; sans feuille nageurs
ni lignes de référence) à une synthèse natation course (docs/V3-synthese-entree.md).

Usage :
  python3 fusion_synthese_nc.py synthese_NC.xlsx complement.xlsx sortie.xlsx \
      --ref="NOM Prénom=COMP1,COMP2" [--ref=...]

- Compétition de référence de chaque athlète : la 1re de sa liste --ref présente dans le complément.
- Par épreuve, le meilleur tour (temps le plus bas) de cette compétition.
- par50 / phases : le complément n'a pas de colonne « tour » ; les courses sont séparées à chaque « 0-50 m »
  (par50) ou à chaque phase répétée (phases), et la course retenue est celle dont le dernier passage
  est égal au temps retenu ; phases suit le même ordre de courses que par50.
- Références (top 3) : celles déjà présentes dans la synthèse pour la même épreuve et le même sexe.
Aucune donnée nominative dans ce script.
"""
import sys
from collections import OrderedDict
import openpyxl

NOMS_COMP = {
    'CEJ 2026 Munich': 'Championnats d’Europe juniors — Munich 2026',
    'CFu18 2026 Chalon Sur Saone': 'Championnats de France juniors (18 ans et moins) — Chalon-sur-Saône 2026',
    'CF 2026 St Etienne': 'Championnats de France Élite — Saint-Étienne 2026',
    'CE 2026 Paris': 'Championnats d’Europe — Paris 2026',
}
MOIS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
        'septembre', 'octobre', 'novembre', 'décembre']


def sec(t):
    v = 0.0
    for x in str(t).split(':'):
        v = v * 60 + float(x)
    return v


def lire(wb, nom):
    rows = list(wb[nom].iter_rows(values_only=True))
    return list(rows[0]), [list(r) for r in rows[1:] if any(c is not None for c in r)]


def dates_fr(isos):
    ds = sorted({d for d in isos if d})
    if not ds:
        return ''
    par_mois = OrderedDict()
    for d in ds:
        par_mois.setdefault((d[:4], int(d[5:7])), []).append('1er' if int(d[8:10]) == 1 else str(int(d[8:10])))
    out = []
    for (an, m), j in par_mois.items():
        out.append((j[0] if len(j) == 1 else ', '.join(j[:-1]) + ' et ' + j[-1]) + ' ' + MOIS[m - 1])
    return ', '.join(out) + ' ' + ds[-1][:4]


def courses(rows, i_key, debut):
    """Découpe des lignes consécutives d'une même clé en courses."""
    out = {}
    for r in rows:
        k = i_key(r)
        lst = out.setdefault(k, [])
        if not lst or debut(r, lst[-1]):
            lst.append([])
        lst[-1].append(r)
    return out


def main():
    a = [x for x in sys.argv[1:] if not x.startswith('--')]
    f_syn, f_comp, f_out = a
    prio = {}
    for x in sys.argv[1:]:
        if x.startswith('--ref='):
            nom, comps = x[6:].split('=', 1)
            prio[nom.strip()] = [c.strip() for c in comps.split(',')]

    syn = openpyxl.load_workbook(f_syn, data_only=True)
    cpl = openpyxl.load_workbook(f_comp, data_only=True)
    hR, R = lire(cpl, 'resultats')
    hP, P = lire(cpl, 'par50')
    hQ, Q = lire(cpl, 'phases')
    iR, iP, iQ = ({c: i for i, c in enumerate(h)} for h in (hR, hP, hQ))

    retenus, nageurs, notes = [], [], []
    for nag in OrderedDict.fromkeys(r[iR['nageur']] for r in R):
        lignes = [r for r in R if r[iR['nageur']] == nag]
        comps = [c for c in prio.get(nag, []) if any(r[iR['competition']] == c for r in lignes)]
        if not comps:
            notes.append(f'{nag} : aucune compétition de --ref dans le complément, ignoré')
            continue
        comp = comps[0]
        meilleurs = OrderedDict()
        for r in lignes:
            if r[iR['competition']] != comp:
                continue
            e = r[iR['epreuve']]
            if e not in meilleurs or sec(r[iR['temps']]) < sec(meilleurs[e][iR['temps']]):
                meilleurs[e] = r
        ecartes = [f"{r[iR['epreuve']]} {r[iR['competition']]} {r[iR['tour']]} {r[iR['temps']]}"
                   for r in lignes if r not in meilleurs.values()]
        if ecartes:
            notes.append(f'{nag} : non retenus : ' + ' ; '.join(ecartes))
        retenus += list(meilleurs.values())
        sexe = lignes[0][iR['sexe']]
        mots = nag.split()
        nageurs.append([None, ' '.join(mots[:-1]), mots[-1], sexe, 'natation-bassin', NOMS_COMP.get(comp, comp),
                        dates_fr(r[iR['date']] for r in meilleurs.values()), 'trouvé',
                        'analyses complémentaires' + ('' if all(r[iR['date']] for r in meilleurs.values())
                                                      else ' ; date inconnue pour une épreuve')])

    kP = courses(P, lambda r: (r[iP['nageur']], r[iP['epreuve']], r[iP['competition']]),
                 lambda r, c: r[iP['segment']] == '0-50 m')
    kQ = courses(Q, lambda r: (r[iQ['nageur']], r[iQ['epreuve']], r[iQ['competition']]),
                 lambda r, c: (r[iQ['longueur']], r[iQ['phase']]) in [(x[iQ['longueur']], x[iQ['phase']]) for x in c])
    P2, Q2 = [], []
    for r in retenus:
        k = (r[iR['nageur']], r[iR['epreuve']], r[iR['competition']])
        cs = kP.get(k, [])
        idx = [i for i, c in enumerate(cs) if sec(c[-1][iP['passage']]) == sec(r[iR['temps']])]
        if len(idx) != 1:
            notes.append(f'{k} : course par 50 m introuvable ou ambiguë ({len(idx)}), par50 et phases omis')
            continue
        P2 += cs[idx[0]]
        qs = kQ.get(k, [])
        if len(qs) == len(cs):
            Q2 += qs[idx[0]]
        else:
            notes.append(f'{k} : {len(qs)} jeux de phases pour {len(cs)} courses, phases omises')

    def ajouter(nom, rows, hsrc):
        ws = syn[nom]
        hdst = [c.value for c in ws[1]]
        for r in rows:
            ws.append([r[hsrc.index(c)] if c in hsrc else None for c in hdst])

    ajouter('nageurs', nageurs, ['licence', 'nom', 'prenom', 'sexe', 'discipline', 'competition_reference',
                                 'dates', 'statut', 'remarque'])
    ajouter('resultats', retenus, hR)
    ajouter('par50', P2, hP)
    ajouter('phases', Q2, hQ)
    hS, S = lire(cpl, 'sources')
    ajouter('sources', S, hS)
    syn.save(f_out)
    print(f'{len(nageurs)} athlètes, {len(retenus)} épreuves, {len(P2)} lignes par50, {len(Q2)} lignes phases')
    for n in notes:
        print(' -', n)


if __name__ == '__main__':
    main()
