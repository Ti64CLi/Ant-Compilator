*17*

func #ASerachFood() {

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
    } *choisis une direction aléatoirement*
 
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
    } *va là où il y a de la nouriture, s il y en a*

    if (
        or(
            is(bit(0),here),
            or(
                is(bit(1),here),
                or(
                    is(bit(2),here),
                    or(
                        is(bit(3),here),
                        or(
                            is(bit(4),here),
                            is(bit(5),here)
                        )
                    )
                )
            )
        )
    )
    then {
        nop;
    }
    else {
        mark(!00);
    } *marque sa direction si le chemin n est pas déjà marqué*

    if (
        or(
            is(friend,ahead),
            is(friendWithFood,ahead)
        )
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
    } *contourne un allié si il y en a un sur le passage*
    else {
        if (
            is(rock,ahead)
        )
        then {
            turn(3);
            goto #D10;
            #A10:
        }
        else {
            move(1);
        }
    } *fais demi-tour si il y a un rocher, avance sinon*

    pickup(#ASerachFood); *si pas de nouriture, refais une recherche*
    turn(3); *sinon, fais demi-tour et rammene la nouriture*
    goto #D2;
    #A2:
    call #ABackFood; *essaye de prendre de la nouriture*

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
        is(bit(!00),here)
    )
    then {
        nop;
    }
    else {
        if (
            is(bit(!01),here)
        )
        then {
            turn(1);
            goto #B13;
            A13:
        }
        else {
            if (
                is(bit(!02),here)
            )
            then {
                turn(2);
                goto #C14;
                A14:
            }
            else {
                if (
                    is(bit(!03),here)
                )
                then {
                    turn(3);
                    goto #D15;
                    A15:
                }
                else {
                    if (
                        is(bit(!04),here)
                    )
                    then {
                        turn(4);
                        goto #E16;
                        A16:
                    }
                    else {
                        if (
                            is(bit(!05),here)
                        )
                        then {
                            turn(5);
                            goto #F17;
                            A17:
                        }
                        else {
                    
                        }
                    }
                }
            }
        }
    } *suivit du chemin de retour*
    *le numéro du bit à tester dépend de l orientation de la fourmi*
    move(1);
}