A = {'A':'A','B':'B','C':'C','D':'D','E':'E','F':'F'}
B = {'A':'B','B':'C','C':'D','D':'E','E':'F','F':'A'}
C = {'A':'C','B':'D','C':'E','D':'F','E':'A','F':'B'}
D = {'A':'D','B':'E','C':'F','D':'A','E':'B','F':'C'}
E = {'A':'E','B':'F','C':'A','D':'B','E':'C','F':'D'}
F = {'A':'F','B':'A','C':'B','D':'C','E':'D','F':'E'}

dfichier = open("decompressed-code","w")

for d in [A,B,C,D,E,F]:
    fichier = open("code","r")
    c = " "
    w = False
    while c:
        c = fichier.read(1)
        if w:
            dfichier.write(d[c])
            w = False
        elif c == '#':
            w = True
        else:
            dfichier.write(c)
    fichier.close()


dfichier.close()