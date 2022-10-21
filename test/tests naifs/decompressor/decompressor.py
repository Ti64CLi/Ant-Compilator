A = {'A':'A','B':'B','C':'C','D':'D','E':'E','F':'F','01':1,'02':2,'03':3,'04':4,'05':5,'00':0}
B = {'A':'B','B':'C','C':'D','D':'E','E':'F','F':'A','01':2,'02':3,'03':4,'04':5,'05':0,'00':1}
C = {'A':'C','B':'D','C':'E','D':'F','E':'A','F':'B','01':3,'02':4,'03':5,'04':0,'05':1,'00':2}
D = {'A':'D','B':'E','C':'F','D':'A','E':'B','F':'C','01':4,'02':5,'03':0,'04':1,'05':2,'00':3}
E = {'A':'E','B':'F','C':'A','D':'B','E':'C','F':'D','01':5,'02':0,'03':1,'04':2,'05':3,'00':4}
F = {'A':'F','B':'A','C':'B','D':'C','E':'D','F':'E','01':0,'02':1,'03':2,'04':3,'05':4,'00':5}

dfichier = open("decompressed-code","w")

for d in [A,B,C,D,E,F]:

    fichier = open("code","r")
    c = " "
    commit = False
    n = 1
    couple = False

    while c:
        c = fichier.read(1)
        if c == '*':
            commit = not commit

        if c == '!':
            c = fichier.read(2)
            dfichier.write(str(d[c]))
        elif not commit and c != '*':
            if c == '#':
                c = fichier.read(1)
                c2 = fichier.read(1)
                dfichier.write(d[c])
                if c2 == ';' or c2 == ':':
                    dfichier.write(str(n))
                    if couple:
                        n += 1
                    couple = not couple
                dfichier.write(c2)
            else :
                dfichier.write(c)

    fichier.close()


dfichier.close()