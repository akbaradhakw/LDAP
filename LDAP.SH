#!/bin/sh
read -p "masukan dc (example) :" ex
read -p "masukan dc (com) :" com
menu(){
    echo "pilih 😂"
    echo "1.install ldap"
    echo "2.add user"
    echo "3.add group"
    echo "4.append to group"
    read -p "pilih bg :" menu
    case $menu in
        1)
            install_ldap
        ;;
        2)
            add_user
        ;;
        3)
            add_group
        ;;
        4)
            append_to_group
        ;;
    esac
}

install_ldap(){
    sudo apt install slapd ldap-utils -y
    sudo dpkg-reconfigure slapd
    ldap_path="/etc/ldap/ldap.conf"
    read -p "masukan URI (ldap.example.com)" URI
    sed -i "s|^#BASE\s\+dc=[a-zA-Z]\+,dc=[a-zA-Z]\+|BASE   dc=$ex,dc=$com|" "$ldap_path"
    sed -i "s|^#URI\s\+ldap:\/\/[a-zA-Z0-9.-]\+|URI    ldap://$URI|" "$ldap_path"
    cat <<EOF > basegroup.ldif
dn: ou=people,dc=$ex,dc=$com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=$ex,dc=$com
objectClass: organizationalUnit
ou: groups
EOF
ldapadd -x -D cn=admin,dc=$ex,dc=$com -W -f basegroup.ldif
}

add_user(){
    create_user(){
        read -p "Nama  :" Name
        read -p "User Password :" ldap_pswd
        read -p "masukan gid (1000) :" gid
    cat << EOF > user.ldif
dn: uid=$Name,ou=people,dc=lks,dc=id
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $Name
sn: $Name
cn: $Name
uidNumber: $gid
gidNumber: $gid
userPassword: $ldap_pswd
gecos: $Name
loginShell: /bin/bash
homeDirectory: /home/$Name

EOF
        ldapadd -x -D cn=admin,dc=$ex,dc=$com -W -f user.ldif
    }
    
    while true; do
        create_user
        
        echo "Do you want to create another user? (yes/no)"
        read choice
        
        case $choice in
            [yY]|[yY][eE][sS]) ;;
            *) break ;;
        esac
    done
}
add_group(){
    create_group(){
        read -p "cn (group_name) :" CNS
        read -p "GID (number):" GID
    cat << EOF > group.ldif
dn: cn=$CNS,ou=groups,dc=$ex,dc=$com
objectClass: posixGroup
cn: $CNS
gidNumber: $GID
EOF
        ldapadd -x -D cn=admin,dc=$ex,dc=$com -W -f group.ldif
        
    }
    while true; do
        create_group
        
        echo "Do you want to create another group? (yes/no)"
        read choice
        
        case $choice in
            [yY]|[yY][eE][sS]) ;;
            *) break ;;
        esac
    done
}
append_to_group(){
read -p "masukan nama group" grup
read -p "masukan nama user" usr
cat <<EOF > a.ldif
dn: cn=$grup,ou=Groups,dc=$ex,dc=$com
changetype: modify
add: member
member: uid=$usr,ou=People,dc=$ex,dc=$com
EOF
}

menu