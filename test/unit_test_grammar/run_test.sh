

# lancement des test dans unit_test_grammar
EXE = ../../antsc
TESTS = $(find . -maxdepth 1 -name \*.ant)

for i in $TESTS; do
    $(EXE) $i;
done;