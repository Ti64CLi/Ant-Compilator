*9*

func #ASerachFood() {

    test(food) in {
        case ahead :
            nop;
        case left :
            turn(5);
            goto #F0;
            #A0:
        case right :
            turn(1);
            goto #B1;
            #A1:
    }

    mark(0);

    if (
        or(is(friend,ahead),is(friendWithFood,ahead))
    )
    then {
        turn(1);
        goto #B7;
        #A7:
        move(1);
        turn(5);
        goto #F8;
        #A8:
        move(1);
        turn(1);
        goto #B9;
        #A9;
    }
    else {
        do {
            turn(3);
        }
        if (
            is(rock,ahead)
        )
    }

    pickup(#ASerachFood);
    turn(3);
    goto #D2;
    #A2:
    call #ABackFood;

    test(randint(3)) in {
        case 1 : {
            turn(5);
            goto #F3;
            #A3:
        }
        case 2 : {
            turn(1);
            goto #B4;
            #A4:
        }
        move(1);
    }
}
func #ABackFood{
    do {
        drop();
        turn(3);
        goto #D5;
        #A5:
        call #ASerachFood;
    }
    if (
        is(home,here)
    )
    if (
        is(bit(3),ahead)
    )
    then{
        move(1);
    }
    else{
        turn(1);
        goto #B6;
        #A6:
    }
}