*23*

func #ASearchFood() {

    if (
        food is left
    )
    then {
        turn(5);
        goto #F;
        #A:
        call #APickUpFood;
    }
    else {
        if (
            food is right
        )
        then {
            turn(1);
            goto #B;
            #A:
            call #APickUpFood;
        }
        else {
            do {
                call #APickUpFood;
            }
            if (
                food is ahead
            )
        }
   } *se tourne vers là où il y a de la nouriture, si il y en a et va en pickup dans ce cas*

    

    if (
        bit(!00) is here
    )
    then {
        nop;
    }
    else {
        if (
        bit(!01) is here
        )
        then {
            nop;
        }
        else {
            if (
                bit(!02) is here
            )
            then {
                nop;
            }
            else {   
                if (
                    bit(!03) is here
                )
                then {
                    nop;
                }
                else {   
                    if (
                        bit(!04) is here
                    )
                    then {
                        nop;
                    }
                    else {   
                        if (
                            bit(!05) is here
                        )
                        then {
                            nop;
                        }
                        else {   
                            mark(!00);
                        }
                    }
                }
            }
        }
    } *marque sa direction si le chemin n est pas déjà marqué*


    if (
        friendWithFood is ahead
    )
    then {
        turn(1);
        goto #B;
        #A:
        move(1);
        turn(5);
        goto #F;
        #A:
        move(1);
        turn(1);
        goto #B;
        #A;
    } *contourne un allié si il y en a un sur le passage*
    else {
        if (
            rock is ahead
        )
        then {
            turn(3);
            goto #D;
            #A:
        }
        else {
            move(1);
        }
    } *fais demi-tour si il y a un rocher, avance sinon*
}

func #APickUpFood {
    if (
        bit(!00) is here
    )
    then {
        nop;
    }
    else {
        if (
        bit(!01) is here
        )
        then {
            nop;
        }
        else {
            if (
                bit(!02) is here
            )
            then {
                nop;
            }
            else {   
                if (
                    bit(!03) is here
                )
                then {
                    nop;
                }
                else {   
                    if (
                        bit(!04) is here
                    )
                    then {
                        nop;
                    }
                    else {   
                        if (
                            bit(!05) is here
                        )
                        then {
                            nop;
                        }
                        else {   
                            mark(!01);
                        }
                    }
                }
            }
        }
    } *marque sa direction si le chemin n est pas déjà marqué*

    if (
        friendWithFood is ahead
    )
    then {
        turn(1);
        goto #B;
        #A:
        move(1);
        turn(5);
        goto #F;
        #A:
        move(1);
        turn(1);
        goto #B;
        #A;
    } *contourne un allié si il y en a un sur le passage*
    else {
        if (
            rock is ahead
        )
        then {
            turn(3);
            goto #D;
            #A:
        }
        else {
            move(1);
        }
    } *fais demi-tour si il y a un rocher, avance sinon*

    pickup(#ASerachFood); *si pas de nouriture, refais une recherche*
    turn(3); *sinon, fais demi-tour et rammene la nouriture*
    goto #D;
    #A:
    call #ABackFood; *essaye de prendre de la nouriture*
}

func #ABackFood{
    do {
        drop();
        turn(3);
        goto #D;
        #A:
        call #ASerachFood;
    }
    if (
        home is here
    )

    if (
        bit(!00) is here
    )
    then {
        nop;
    }
    else {
        if (
            bit(!01) is here
        )
        then {
            turn(1);
            goto #B;
            #A:
        }
        else {
            if (
                bit(!02) is here
            )
            then {
                turn(2);
                goto #C;
                #A:
            }
            else {
                if (
                    bit(!03) is here
                )
                then {
                    turn(3);
                    goto #D;
                    #A:
                }
                else {
                    if (
                        bit(!04) is here
                    )
                    then {
                        turn(4);
                        goto #E;
                        #A:
                    }
                    else {
                        if (
                            bit(!05) is here
                        )
                        then {
                            turn(5);
                            goto #F;
                            #A:
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