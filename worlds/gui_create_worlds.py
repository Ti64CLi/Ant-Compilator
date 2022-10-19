import pygame as py
from random import randint

# Choose the size of your world
# zoom = int(input("zoom : "))
# height = int(input("height : "))
# length = int(input("lenght : "))
zoom = 1
length = 100
height = 100
square = 8

# Numéro to print for FOOD number
py.font.init()
my_font = py.font.SysFont('Comic Sans MS', int(square*2/3))
num_font = [my_font.render(" " + str(i), False, (0, 0, 0)) for i in range(10)]
map = [[0]*length for i in range(height)]

# New Object State in the map


class State:
    def __init__(self, name, i, color, char, key):
        self.name = name
        self.integer = i
        self.color = color
        self.char = char
        self.char_render = my_font.render(self.char, False, (0, 0, 0))
        self.key = key

    def blit(self, window, i, j):
        # py.draw.polygon(window, (255, 0, 0),[[300, 300], [100, 400],[100, 300]])
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
l_state.append(State("EMPTY", 0, BLANC, " .", py.K_a))
l_state.append(State("ROCK", 1, VERT, " #", py.K_z))
l_state.append(State("TEAM_1", 2, ROUGE, " -", py.K_e))
l_state.append(State("TEAM_2", 3, NOIR, " +", py.K_r))
l_state.append(State("FOOD_0", 4, YELLOW, " 0", py.K_t))
l_state.append(State("FOOD_1", 6, YELLOW, " 1", py.K_q))
l_state.append(State("FOOD_2", 7, YELLOW, " 2", py.K_s))
l_state.append(State("FOOD_3", 8, YELLOW, " 3", py.K_d))
l_state.append(State("FOOD_4", 9, YELLOW, " 4", py.K_f))
l_state.append(State("FOOD_5", 10, YELLOW, " 5", py.K_g))
l_state.append(State("FOOD_6", 11, YELLOW, " 6", py.K_w))
l_state.append(State("FOOD_7", 12, YELLOW, " 7", py.K_x))
l_state.append(State("FOOD_8", 13, YELLOW, " 8", py.K_c))
l_state.append(State("FOOD_9", 14, YELLOW, " 9", py.K_v))


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
            update_cell(window, t, i, j)


def update_cell(window, t, i, j):
    l_state[t[i][j]].blit(window, i, j)


def draw_line(window):
    for p in range(height):
        py.draw.line(window, NOIR, (0*square, p * square),
                     ((height-1) * square, p * square), width=1)
    for p in range(length):
        py.draw.line(window, NOIR, (p*square, 0*square),
                     (p*square, (height-1) * square), width=1)


def draw_border(t):
    for i in range(len(t)):
        for j in range(len(t[0])):
            if i == 0 or i == len(t)-1 or j == 0 or j == len(t[0])-1:
                # ROCK on the borders
                t[i][j] = 1


def write_map(NomFich, t):

    f = open(NomFich, "w")
    f.write(str(zoom) + "\n")
    f.write(str(length) + "\n")
    f.write(str(height) + "\n")
    for lgn in range(len(t)):
        if lgn % 2 == 1:
            f.write(" ")
        for row in range(len(t[lgn])):

            f.write(l_state[t[lgn][row]].char)
            f.write(" ")
            if row == len(t[lgn])-1:
                if lgn != len(t)-1:
                    f.write("\n")
    f.close()


def create_array_gui(map):
    draw_border(map)
    py.init()
    window = py.display.set_mode((length*square, height*square), py.SHOWN)
    draw_screen(window, map)
    draw_line(window)
    py.display.flip()
    py.key.set_repeat(10, 10)
    Test = True
    while Test:
        for event in py.event.get():
            # condition d'arrêt
            if event.type == py.QUIT:
                Test = False
            if event.type == py.KEYDOWN and event.key == py.K_ESCAPE:
                Test = False
            if event.type == py.KEYDOWN and event.key == py.K_SPACE:
                Test = False

            for i in range(14):
                if event.type == py.KEYDOWN and event.key == l_state[i].key:
                    x, y = py.mouse.get_pos()
                    x_j = x // square
                    y_i = y // square
                    map[y_i][x_j] = i
                    update_cell(window, map, y_i, x_j)
                    draw_line(window)
                    py.display.flip()
    py.quit()


create_array_gui(map)
print(map)

A = input("ENREGISTRER ? Yes(Y) / No(N) ")
if A == "Y":
    name = input("nom de la map creer : ")
    write_map("worlds/" + name + ".world", map)
