def create_goto(g, label):
    code = []
    for i in range(g):
        code += ["  Goto label" + str(label)]
        code += ["label" + str(label) + ":"]
        label += 1
    
    return (label, code)

def create_move(n, g, label):
    code = []
    for i in range(n):
        code += ["  Move label" + str(label)]
        code += ["  Goto label" + str(label)]
        code += ["label" + str(label) + ":"]
        label += 1
        (label, newCode) = create_goto(g, label)
        code += newCode
    
    return code

def main():
    name = input("Filname (without .brain) : ")
    n = int(input("Number of moves : "))
    g = int(input("Number of gotos for each move : "))
    code = ["label0:"]
    code += create_move(n, g, 1)

    with open(name + ".brain", "w") as file:
        for line in code:
            file.write(line + "\n")

main()