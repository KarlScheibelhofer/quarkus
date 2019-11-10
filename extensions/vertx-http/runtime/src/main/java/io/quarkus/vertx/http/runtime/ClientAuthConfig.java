package io.quarkus.vertx.http.runtime;

import java.nio.file.Path;
import java.util.Optional;

import io.quarkus.runtime.annotations.ConfigGroup;
import io.quarkus.runtime.annotations.ConfigItem;
import io.vertx.core.http.ClientAuth;

/**
 * A configuration for SSL/TLS client authentication.
 */
@ConfigGroup
public class ClientAuthConfig {

    /**
     * The type of client authentication, i.e. none, required or request.
     * If unspecified, the default of the underlying implementation is used,
     * which is usually none.
     */
    @ConfigItem
    public Optional<ClientAuth> type;

    /**
     * The file path to the store with trusted CA certificates.
     */
    @ConfigItem
    public Optional<Path> trustStoreFile;

    /**
     * An optional parameter to specify type of the trust store file. If not given, the type is automatically detected
     * based on the file name.
     * File ending in ".p12", ".pkcs12" and ".pfx" are considered type PKCS12.
     * Files with extension ".pem" are read as list of PEM certificates (OpenSSL).
     * JKS is the default type, if no type is given and the file extension is unknown.
     */
    @ConfigItem
    public Optional<String> trustStoreFileType;

    /**
     * A parameter to specify the password of the key store file. If not given, the default ("password") is used.
     */
    @ConfigItem(defaultValue = "password")
    public String trustStorePassword;
}
