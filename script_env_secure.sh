#!/bin/bash

IMG="coffre.img"
MAPPER="coffre"
MOUNTPOINT="/mnt/coffre"

usage() {
    echo "Commande: $0 {install|open|close}"
    exit 1
}

install_env() {
    #Demande la taille à l'utilisateur
    read -p "Taille de l'environnement (ex: 5G, 10G): " SIZE
    SIZE=${SIZE:-5G}

    #Demander le mot de passe à l'utilisateur (il sera utilisé lors de la saisie cryptsetup)

    #Création du fichier de la taille choisie
    #Gestion G/M/K pour la taille
    if [[ $SIZE == *G ]]; then
        COUNT=${SIZE%G}
        BS=1G
    elif [[ $SIZE == *M ]]; then
        COUNT=${SIZE%M}
        BS=1M
    elif [[ $SIZE == *K ]]; then
        COUNT=${SIZE%K}
        BS=1K
    else
        # Par défaut, 5G
        COUNT=5
        BS=1G
    fi

    dd if=/dev/zero of="$IMG" bs=$BS count=$COUNT

    #Chiffrement LUKS (le mot de passe sera demandé)
    sudo cryptsetup luksFormat "$IMG"

    #Ouvrir le volume chiffré
    sudo cryptsetup luksOpen "$IMG" "$MAPPER"

    #Formater en ext4
    sudo mkfs.ext4 "/dev/mapper/$MAPPER"

    #Fermer le volume
    sudo cryptsetup luksClose "$MAPPER"

    echo "Installation terminée."
}

open_env() {
    sudo cryptsetup luksOpen "$IMG" "$MAPPER"
    sudo mkdir -p "$MOUNTPOINT"
    sudo mount "/dev/mapper/$MAPPER" "$MOUNTPOINT"
    echo "Environnement ouvert et monté sur $MOUNTPOINT"
}

close_env() {
    sudo umount "$MOUNTPOINT"
    sudo cryptsetup luksClose "$MAPPER"
    echo "Environnement fermé."
}

case "$1" in
    install)
        install_env
        ;;
    open)
        open_env
        ;;
    close)
        close_env
        ;;
    *)
        usage
        ;;
esac

