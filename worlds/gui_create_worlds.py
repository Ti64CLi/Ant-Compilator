from curses import KEY_SAVE
import pygame as py
from random import randint

# hauteur de son écran
HAUTEUR_SCREEN = 1600
# CHOOSE THE SIZE OF THE WORLD
#zoom = int(input("zoom : "))
#height = int(input("height : "))
#length = int(input("lenght : "))
zoom = 1
length = 10
height = 10
square = (HAUTEUR_SCREEN * 5) // (height * 10)
square -= (square % 6)
# symetry : "axial_x", "axial_y", "central", "diag"]
symetry = "central"

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
BLEU = (0, 0, 255)
FOND = VERT

# 4+i -> i FOOD
offset_FOOD = 4
# square index
square_index = [(0, 0), (0, 1), (1, 0), (1, 1)]
base = []

# Numero to print for FOOD number
py.font.init()
my_font = py.font.SysFont('Comic Sans MS', int(square*2/3))
num_font = [my_font.render(" " + str(i), False, (0, 0, 0)) for i in range(10)]
# Init of the Map
map = [[0]*length for i in range(height)]

# New Object State in each cell of the map


class State:
    def __init__(self, name, i, color, char, key_s, key_l):
        self.name = name
        self.integer = i
        self.color = color
        self.char = char
        self.char_render = my_font.render(self.char, False, (0, 0, 0))
        self.key_small = key_s
        self.key_large = key_l

    def blit(self, window, pi, pj):
        py.draw.polygon(window, self.color, create_hexagon(pi, pj))
        # py.draw.rect(window, self.color, [square*j, square*i, square, square])
        window.blit(self.char_render, [pi, pj])


# Different type of cells

l_state = []
l_state.append(State("EMPTY", 0, BLANC, " .", py.K_a, py.K_z))
l_state.append(State("ROCK", 1, VERT, " #", py.K_e, py.K_r))
l_state.append(State("TEAM_1", 2, ROUGE, " -", py.K_t, py.K_y))
l_state.append(State("TEAM_2", 3, NOIR, " +", py.K_q, py.K_s))
l_state.append(State("FOOD_0", 4, YELLOW, " 0", py.K_p, py.K_p))
l_state.append(State("FOOD_1", 5, YELLOW, " 1", py.K_p, py.K_p))
l_state.append(State("FOOD_2", 6, YELLOW, " 2", py.K_p, py.K_p))
l_state.append(State("FOOD_3", 7, YELLOW, " 3", py.K_p, py.K_p))
l_state.append(State("FOOD_4", 8, YELLOW, " 4", py.K_p, py.K_p))
l_state.append(State("FOOD_5", 9, YELLOW, " 5", py.K_w, py.K_x))
l_state.append(State("FOOD_6", 10, YELLOW, " 6", py.K_p, py.K_p))
l_state.append(State("FOOD_7", 11, YELLOW, " 7", py.K_p, py.K_p))
l_state.append(State("FOOD_8", 12, YELLOW, " 8", py.K_p, py.K_p))
l_state.append(State("FOOD_9", 13, YELLOW, " 9", py.K_c, py.K_v))
number_of_state = len(l_state)


def symetrical(sym, i, j):
    if sym == "axial_x":
        return (i, j)
    if sym == "axial_y":
        return (i, j)
    if sym == "central":
        return (height - 1 - i, length - 1 - j)
    if sym == "diag":
        return (j, i)


def create_hexagon(pi, pj):
    hexagon = []
    # haut gauche
    hexagon.append([pi, pj])
    # haut
    hexagon.append([pi + square//2, pj - square//3])
    # haut droite
    hexagon.append([pi + square, pj])
    # bas droite
    hexagon.append([pi + square, pj + 2 * (square // 3)])
    # bas
    hexagon.append([pi + square//2, pj + square])
    # bas gauche
    hexagon.append([pi, pj + 2 * (square // 3)])
    return hexagon


def lecture_map(file_name):
    map_from_file = []
    f = open(file_name, "r")
    f.close()
    return map_from_file


def draw_screen(window, t):
    for i in range(len(t)):
        for j in range(len(t[0])):
            update_cell(window, t, i, j)


def update_cell(window, t, i, j):
    l_state[t[i][j]].blit(window, square*i + (j % 2) * square//2, square*j)


def draw_line_square(window):
    for p in range(height):
        py.draw.line(window, NOIR, (0*square, p * square),
                     ((height-1) * square, p * square), width=1)
    for p in range(length):
        py.draw.line(window, NOIR, (p*square, 0*square),
                     (p*square, (height-1) * square), width=1)


def draw_line_hexagone(window):
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


def draw_case(window, val, i, j, shape):
    si, sj = symetrical(symetry, i, j)
    for p in shape:
        pi, pj = p
        map[i + pi][j + pj] = val
        if l_state[val].name == "TEAM_1" or l_state[val].name == "TEAM_2":
            map[si + pi][sj + pj] = 5 - val
        else:
            map[si + pi][sj + pj] = val
        update_cell(window, map, i + pi, j + pj)
        update_cell(window, map, si + pi, sj + pj)


def create_array_gui(map):
    draw_border(map)
    py.init()
    window = py.display.set_mode((length*square, height*square), py.SHOWN)
    window.fill(FOND)
    draw_screen(window, map)
    # draw_line(window)
    py.display.flip()
    py.key.set_repeat(10, 10)
    Test = True
    while Test:
        py.display.flip()
        for event in py.event.get():
            # condition d'arrêt
            if event.type == py.QUIT:
                Test = False
            if event.type == py.KEYDOWN and event.key == py.K_ESCAPE:
                Test = False
            if event.type == py.KEYDOWN and event.key == py.K_SPACE:
                Test = False

            for val in range(number_of_state):
                x, y = py.mouse.get_pos()
                i = x // square
                j = y // square
                si, sj = symetrical(symetry, i, j)
                # small
                if event.type == py.KEYDOWN and event.key == l_state[val].key_small:
                    draw_case(window, val, i, j, [(0, 0)])
                # large
                if event.type == py.KEYDOWN and event.key == l_state[val].key_large:
                    draw_case(window, val, i, j, square_index)
    py.quit()


create_array_gui(map)
print(map)

A = input("ENREGISTRER ? Yes(Y) / No(N) ")
if A == "Y":
    name = input("nom de la map creer : ")
    write_map("worlds/" + name + ".world", map)
