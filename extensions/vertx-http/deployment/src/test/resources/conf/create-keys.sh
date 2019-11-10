#!/bin/bash
# This script generates keys and certificates for testing.
# It uses the java keytool and openssl. Both must be in PATH.
# Keys and certificates are stored in JKS, PKCS#12 and OpenSSL format.
# The script creates a CA, a server and a client certificate.
# The keys are RSA 2048, which are sufficient for these tests.

# the password for all keystores
export SECRET=secret

# declare files names
export JKS_FILE_CA=ca.jks
export CER_FILE_CA=ca.cer

export JKS_TRUST_STORE=truststore.jks
export P12_TRUST_STORE=truststore.p12
export PEM_TRUST_STORE=truststore.pem

export JKS_FILE_CLIENT=client-keystore.jks
export CER_FILE_CLIENT=client.cer
export P12_FILE_CLIENT=client-keystore.p12
export PEM_FILE_CER_CLIENT=client-cert.pem
export PEM_FILE_KEY_CLIENT=client-key.pem

export JKS_FILE_SERVER=server-keystore.jks
export CER_FILE_SERVER=server.cer
export P12_FILE_SERVER=server-keystore.p12
export CRT_FILE_SERVER=localhost.crt
export PEM_FILE_CER_SERVER=server-cert.pem
export PEM_FILE_KEY_SERVER=server-key.pem


# cleanup files
rm -f \
  ${JKS_FILE_CA} \
  ${CER_FILE_CA} \
  ${JKS_TRUST_STORE} \
  ${P12_TRUST_STORE} \
  ${PEM_TRUST_STORE} \
  ${JKS_FILE_CLIENT} \
  ${CER_FILE_CLIENT} \
  ${P12_FILE_CLIENT} \
  ${PEM_FILE_CER_CLIENT} \
  ${PEM_FILE_KEY_CLIENT} \
  ${JKS_FILE_SERVER} \
  ${CER_FILE_SERVER} \
  ${P12_FILE_SERVER} \
  ${CRT_FILE_SERVER} \
  ${PEM_FILE_CER_SERVER} \
  ${PEM_FILE_KEY_SERVER} 

# generate key-pair and certificate for CA
keytool -genkeypair -keyalg RSA -keysize 2048 -validity 7300 \
  -keystore ${JKS_FILE_CA} -keypass ${SECRET} -storepass ${SECRET} -alias cakey \
  -dname CN=CA \
  -ext bc:critical=ca:true \
  -ext ku:critical=keyCertSign,cRLSign
# export CA certificate
keytool -exportcert \
  -keystore ${JKS_FILE_CA} -keypass ${SECRET} -storepass ${SECRET} -alias cakey \
  > ${CER_FILE_CA}

# generate trust stores
# convert the CA certificate to openssl format (PEM)
cat ${CER_FILE_CA} \
  | openssl x509 -inform DER -outform PEM \
  > ${PEM_TRUST_STORE}
# import CA cert into JKS trust store
keytool -importcert \
  -keystore ${JKS_TRUST_STORE} -keypass ${SECRET} -storepass ${SECRET} -alias cacert \
  -noprompt -trustcacerts -file ${CER_FILE_CA}
# import CA cert into PKCS#12 trust store
keytool -importcert \
  -keystore ${P12_TRUST_STORE} -storetype PKCS12 -keypass ${SECRET} -storepass ${SECRET} -alias cacert \
  -noprompt -trustcacerts -file ${CER_FILE_CA}

# generate key-pair for client
keytool -genkeypair -keyalg RSA -keysize 2048 \
  -keystore ${JKS_FILE_CLIENT} -keypass ${SECRET} -storepass ${SECRET} -alias clientkey -dname CN=client
# generate certificate for client
keytool -keystore ${JKS_FILE_CLIENT} -keypass ${SECRET} -storepass ${SECRET} -alias clientkey -certreq \
  | keytool -keystore ${JKS_FILE_CA} -keypass ${SECRET} -storepass ${SECRET} -alias cakey -gencert \
     -validity 3650 -ext ku:critical=digitalSignature -ext eku=clientAuth \
  > ${CER_FILE_CLIENT}
# import CA cert into client keystore
keytool -importcert \
  -keystore ${JKS_FILE_CLIENT} -keypass ${SECRET} -storepass ${SECRET} -alias cacert \
  -noprompt -trustcacerts -file ${CER_FILE_CA}
# import client cert into client keystore
keytool -importcert \
  -keystore ${JKS_FILE_CLIENT} -keypass ${SECRET} -storepass ${SECRET} -alias clientkey \
  -noprompt -trustcacerts -file ${CER_FILE_CLIENT}
# convert client keystore to PKCS#12/PFX format
keytool -importkeystore -srckeystore ${JKS_FILE_CLIENT} -srcstoretype JKS -srcstorepass ${SECRET} \
  -destkeystore ${P12_FILE_CLIENT} -deststoretype PKCS12 -deststorepass ${SECRET}

# export the client key in openssl format (PEM)
cat ${P12_FILE_CLIENT} \
  | openssl pkcs12 -nodes -passin pass:${SECRET} \
  | openssl pkcs8 -topk8 -nocrypt \
  > ${PEM_FILE_KEY_CLIENT}
# convert the client certificate to openssl format (PEM)
cat ${CER_FILE_CLIENT} \
  | openssl x509 -inform DER -outform PEM \
  > ${PEM_FILE_CER_CLIENT}

# generate key-pair for server
keytool -genkeypair -keyalg RSA -keysize 2048 \
  -keystore ${JKS_FILE_SERVER} -keypass ${SECRET} -storepass ${SECRET} -alias serverkey -dname CN=localhost
# generate certificate for server
keytool -keystore ${JKS_FILE_SERVER} -keypass ${SECRET} -storepass ${SECRET} -alias serverkey -certreq \
  | keytool -keystore ${JKS_FILE_CA} -keypass ${SECRET} -storepass ${SECRET} -alias cakey -gencert \
     -validity 3650 -ext ku:critical=digitalSignature -ext eku=serverAuth \
  > ${CER_FILE_SERVER}
# import CA cert into server keystore
keytool -importcert \
  -keystore ${JKS_FILE_SERVER} -keypass ${SECRET} -storepass ${SECRET} -alias cacert \
  -noprompt -trustcacerts -file ${CER_FILE_CA}
# import server cert into server keystore
keytool -importcert \
  -keystore ${JKS_FILE_SERVER} -keypass ${SECRET} -storepass ${SECRET} -alias serverkey \
  -noprompt -trustcacerts -file ${CER_FILE_SERVER}
# convert server keystore to PKCS#12/PFX format
keytool -importkeystore -srckeystore ${JKS_FILE_SERVER} -srcstoretype JKS -srcstorepass ${SECRET} \
  -destkeystore ${P12_FILE_SERVER} -deststoretype PKCS12 -deststorepass ${SECRET}
# export certificate in binary/DER encoding
keytool -exportcert -alias serverkey -file ${CRT_FILE_SERVER} -keystore ${JKS_FILE_SERVER} -keypass ${SECRET} -storepass ${SECRET}

# export the server key in openssl format (PEM)
cat ${P12_FILE_SERVER} \
  | openssl pkcs12 -nodes -passin pass:${SECRET} \
  | openssl pkcs8 -topk8 -nocrypt \
  > ${PEM_FILE_KEY_SERVER}
# convert the server certificate to openssl format (PEM)
cat ${CER_FILE_SERVER} \
  | openssl x509 -inform DER -outform PEM \
  > ${PEM_FILE_CER_SERVER}
