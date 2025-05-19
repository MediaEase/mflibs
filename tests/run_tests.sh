#!/usr/bin/env bash
# file: tests/run_tests.sh

CURRENT_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$CURRENT_DIR")"

BASH_UNIT="$ROOT_DIR/bash_unit"

# Téléchargement si nécessaire
if [ ! -f "$BASH_UNIT" ]; then
    echo "bash_unit non trouvé à l'emplacement $BASH_UNIT"
    echo "Téléchargement de bash_unit..."
    curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/bash_unit > "$BASH_UNIT" && chmod +x "$BASH_UNIT"
    if [ ! -f "$BASH_UNIT" ]; then
        echo "Échec du téléchargement de bash_unit. Veuillez l’installer manuellement."
        exit 1
    fi
fi

# Détection des fichiers de test
TEST_FILES=$(find "$CURRENT_DIR" -name "test_*.sh")

# Préparer l'environnement si besoin
export MFLIBS_LOADED=""

# Exécution
cd "$CURRENT_DIR"
"$BASH_UNIT" -f tap $TEST_FILES

# Résultat
if [ $? -eq 0 ]; then
    echo -e "\n\033[32mTous les tests ont réussi !\033[0m"
else
    echo -e "\n\033[31mCertains tests ont échoué. Veuillez vérifier les erreurs ci-dessus.\033[0m"
fi

