#!/bin/bash

case "$DB_TYPE" in
    "mysql")
        DB_DRIVER_CLASS="com.mysql.cj.jdbc.Driver"
        DB_DRIVER_URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar"
        DB_DRIVER_NAME="mysql-connector.jar"
        ;;
    "postgres"|"postgresql")
        DB_DRIVER_CLASS="org.postgresql.Driver"
        DB_DRIVER_URL="https://jdbc.postgresql.org/download/postgresql-42.6.0.jar"
        DB_DRIVER_NAME="postgres-connector.jar"
        ;;
    *)
        DB_DRIVER_CLASS=""
        DB_DRIVER_URL=""
        DB_DRIVER_NAME=""
        ;;
esac

export DB_DRIVER_CLASS
export DB_DRIVER_PATH="/tmp/$DB_DRIVER_NAME"

setup_install_conf() {
    echo "----------------------------------------------------------------"
    echo "Gerando install.conf a partir do template..."
    mkdir -p /tmp/fluig-installer/
    
    if [ ! -f "$DB_DRIVER_PATH" ] && [ ! -z "$DB_DRIVER_URL" ]; then
        echo "Baixando driver JDBC para $DB_TYPE..."
        curl -L -s -o "$DB_DRIVER_PATH" "$DB_DRIVER_URL"
    fi

    eval "echo \"$(cat /installer/scripts/install.conf.template)\"" > /tmp/fluig-installer/install.conf
    echo "install.conf gerado com sucesso."
    echo "----------------------------------------------------------------"
}

wait_for_db() {
    echo "Aguardando banco de dados ($DB_HOST:$DB_PORT)..."
    until timeout 1 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; do
        sleep 2
    done
    echo "Banco de dados detectado!"
}

echo "Iniciando processo Fluig Voyager 2.0 (FLUIG_UPDATE=$FLUIG_UPDATE)..."

wait_for_db
setup_install_conf

if [ ! -f "$FLUIG_INSTALL_PATH/appserver/standalone/configuration/standalone.xml" ] || [ "$FLUIG_UPDATE" = "true" ]; then
    echo "Preparando diretório para (re)instalação: $FLUIG_INSTALL_PATH"
    find "$FLUIG_INSTALL_PATH" -mindepth 1 -delete
    
    echo "Executando instalação silenciosa..."
    cd /installer/package
    JAVA_BIN=$(find /installer/package/jdk-64/bin -name java)
    INSTALLER_JAR=$(find /installer/package -name "fluig-installer.jar")

    $JAVA_BIN -Xmx512m -DINSTALL_PATH="$FLUIG_INSTALL_PATH" \
              -cp "$INSTALLER_JAR" com.fluig.install.ExecuteInstall \
              /tmp/fluig-installer/install.conf

    if [ $? -eq 0 ]; then
        echo "Instalação concluída com sucesso!"
    else
        echo "ERRO: A instalação falhou."
        exit 1
    fi
else
    echo "Fluig já instalado em $FLUIG_INSTALL_PATH."
fi

XML_CONFIG="$FLUIG_INSTALL_PATH/appserver/standalone/configuration/standalone.xml"

if [ -f "$XML_CONFIG" ]; then
    echo "Aplicando patches no standalone.xml..."
    
    sed -i 's/<inet-address[^>]*\/>/<any-address\/>/g' "$XML_CONFIG"

    SMTP_SERVER=${EMAIL_SERVER:-"smtp.gmail.com"}
    SMTP_PORT=${EMAIL_PORT:-"587"}
    [[ ! "$SMTP_PORT" =~ ^[0-9]+$ ]] && SMTP_PORT="587"

    sed -i "s/__email_smtpServer__/${SMTP_SERVER}/g" "$XML_CONFIG"
    sed -i "s/__email_smtpPort__/${SMTP_PORT}/g" "$XML_CONFIG"
    
    sed -i 's/socket-binding name="http" port="[^"]*"/socket-binding name="http" port="8080"/g' "$XML_CONFIG"
    sed -i 's/127.0.0.1/localhost/g' "$XML_CONFIG"
    
    echo "Patches aplicados com sucesso."
fi

echo "Iniciando o TOTVS Fluig Plataforma..."
chown -R fluig:fluig "$FLUIG_INSTALL_PATH"
cd "$FLUIG_INSTALL_PATH/appserver/bin"
su - fluig -c "cd $FLUIG_INSTALL_PATH/appserver/bin && ./standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0"
