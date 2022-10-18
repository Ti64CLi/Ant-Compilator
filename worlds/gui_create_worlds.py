import pygame as py
from random import randint

# Choose the size of your world
# zoom = int(input("zoom : "))
# height = int(input("height : "))
# length = int(input("lenght : "))
zoom = 3
length = 26
height = 29
square = 30

# Numéro to print for FOOD number
py.font.init()
my_font = py.font.SysFont('Comic Sans MS', int(square*2/3))
num_font = [my_font.render(" " + str(i), False, (0, 0, 0)) for i in range(10)]
map = [[0]*length for i in range(height)]

# New Object State in the map


class State:
    def __init__(self, name, i, color, char):
        self.name = name
        self.integer = i
        self.color = color
        self.char = char
        self.char_render = my_font.render(self.char, False, (0, 0, 0))

    def blit(self, window, i, j):
        #py.draw.polygon(window, (255, 0, 0),[[300, 300], [100, 400],[100, 300]])
        py.draw.rect(window, self.color, [square*j, square*i, square, square])
        window.blit(self.char_render, (square*j, square*i))


# 4+i -> i FOOD
offset_FOOD = 4

# Colors
NOIR = (0, 0, 0)
BLANC = (255, 255, 255)
VERT = (0, 255, 0)
ROUGE = (255, 0,  0)
ROSE = (255, 20, 147)
GR_RG = (132, 46, 27)
GRIS = (122, 145, 145)
MARRON = (165, 42, 42)
ARGENT = (206, 206, 206)
YELLOW = (255, 255, 0)

# Different type of cells
l_state = []
l_state.append(State("EMPTY", 0, BLANC, " ."))
l_state.append(State("ROCK", 1, VERT, " #"))
l_state.append(State("TEAM_1", 2, ROUGE, " -"))
l_state.append(State("TEAM_2", 3, NOIR, " +"))
l_state.append(State("FOOD_0", 4, YELLOW, " 0"))
l_state.append(State("FOOD_1", 6, YELLOW, " 1"))
l_state.append(State("FOOD_2", 7, YELLOW, " 2"))
l_state.append(State("FOOD_3", 8, YELLOW, " 3"))
l_state.append(State("FOOD_4", 9, YELLOW, " 4"))
l_state.append(State("FOOD_5", 10, YELLOW, " 5"))
l_state.append(State("FOOD_6", 11, YELLOW, " 6"))
l_state.append(State("FOOD_7", 12, YELLOW, " 7"))
l_state.append(State("FOOD_8", 13, YELLOW, " 8"))
l_state.append(State("FOOD_9", 13, YELLOW, " 9"))


def creat_hexagon(x, y):
    hexagon = []
    p_i = x*square
    p_j = y*square
    # haut gauche
    hexagon.append([0, 0])
    # haut droite
    hexagon.append([0, 0])
    # droite
    hexagon.append([0, 0])
    # bas droite
    hexagon.append([0, 0])
    # bas gauche
    hexagon.append([0, 0])
    # gauche
    hexagon.append([0, 0])

    return hexagon


def draw_screen(window, t):
    for i in range(len(t)):
        for j in range(len(t[0])):
            l_state[t[i][j]].blit(window, i, j)


def write_map(NomFich, t):

    f = open(NomFich, "w")
    f.write(str(zoom) + "\n")
    f.write(str(length) + "\n")
    f.write(str(height) + "\n")
    for lgn in range(len(t)):
        if lgn % 2 == 1:
            f.write(" ")
        for row in range(len(t[lgn])):

            f.write(l_state(t[lgn][row]).char)
            f.write(" ")
            if row == len(t[lgn])-1:
                if lgn != len(t)-1:
                    f.write("\n")
    f.close()


def create_array_gui(map):
    py.init()

    # foret  = py.transform.scale(foret,(600,b2))
    window = py.display.set_mode((length*square, height*square), py.SHOWN)
    # fenetre.blit(foret,(0,0))

    py.draw.rect(window, VERT, [20, 20, 2, 2])
    # py.key.set_repeat(10, 0)
    Test = True
    while Test:
        draw_screen(window, map)
        py.display.flip()
        for event in py.event.get():
            # condition d'arrêt
            if event.type == py.QUIT:
                Test = False
            if event.type == py.KEYDOWN and event.key == py.K_ESCAPE:
                Test = False
            if event.type == py.KEYDOWN and event.key == py.K_SPACE:
                Test = False

            if event.type == py.MOUSEBUTTONDOWN:
                print("event.button = ", event.button)
                x, y = event.pos
                x_i = x // square
                y_j = y // square
                print("x_i = ", x_i, ", y_i = ", y_j)

                if event.button == 3 and (map[y_j][x_i] >= offset_FOOD):
                    # right click and on a FOOD cell -> increase the FOOD
                    map[y_j][x_i] = ((map[y_j][x_i] - 4 + 1) % 10) + 4

                if event.button == 1:
                    # left click
                    map[y_j][x_i] = (map[y_j][x_i] + 1) % (offset_FOOD+1)

    py.quit()


create_array_gui(map)
A = input("ENREGISTRER ? Yes(Y) / No(N) ")
if A == "Y":
    name = input("nom de la map creer : ")
    write_map(name+".world", map)
