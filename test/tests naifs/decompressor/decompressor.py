A = {'A':'A','B':'B','C':'C','D':'D','E':'E','F':'F','00':0}
B = {'A':'B','B':'C','C':'D','D':'E','E':'F','F':'A','00':1}
C = {'A':'C','B':'D','C':'E','D':'F','E':'A','F':'B','00':2}
D = {'A':'D','B':'E','C':'F','D':'A','E':'B','F':'C','00':3}
E = {'A':'E','B':'F','C':'A','D':'B','E':'C','F':'D','00':4}
F = {'A':'F','B':'A','C':'B','D':'C','E':'D','F':'E','00':5}

dfichier = open("decompressed-code","w")

for d in [A,B,C,D,E,F]:

    fichier = open("code","r")
    c = " "
    commit = False

    while c:
        c = fichier.read(1)
        if c == '*':
            commit = not commit

        if c == '!':
            c = fichier.read(2)
            dfichier.write(str((d['00']+int(c))%6))
        elif not commit and c != '*':
            if c == '#':
                c = fichier.read(1)
                dfichier.write(d[c])
            else :
                dfichier.write(c)

    fichier.close()


dfichier.close()