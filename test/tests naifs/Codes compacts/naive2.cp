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
        friend is ahead
    )
    then {
        turn(1);
        move(1);
        turn(5);
        move(1);
        turn(1);
    }
    else {
        move(1);
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
        home in here
    )
    if (
        bit(3) is ahead
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