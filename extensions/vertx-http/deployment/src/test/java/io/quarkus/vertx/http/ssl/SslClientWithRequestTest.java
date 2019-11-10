package io.quarkus.vertx.http.ssl;

import static org.hamcrest.core.Is.is;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.event.Observes;
import javax.security.cert.X509Certificate;

import org.assertj.core.api.Assertions;
import org.jboss.shrinkwrap.api.ShrinkWrap;
import org.jboss.shrinkwrap.api.spec.JavaArchive;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;

import io.quarkus.test.QuarkusUnitTest;
import io.restassured.RestAssured;
import io.vertx.ext.web.Router;

/**
 * Test client-auth type request with a client providing a certificate.
 */
public class SslClientWithRequestTest {

    @RegisterExtension
    static final QuarkusUnitTest config = new QuarkusUnitTest()
            .setArchiveProducer(() -> ShrinkWrap.create(JavaArchive.class)
                    .addClasses(MyBean.class)
                    .addAsResource(new File("src/test/resources/conf/ssl-client-request.conf"), "application.properties")
                    .addAsResource(new File("src/test/resources/conf/server-keystore.jks"), "server-keystore.jks")
                    .addAsResource(new File("src/test/resources/conf/truststore.jks"), "truststore.jks"));

    @BeforeAll
    public static void setupRestAssured() {
        // do not use relaxed HTTPS validatin because it breaks the client authentication config
        //        RestAssured.useRelaxedHTTPSValidation();
    }

    @AfterAll
    public static void restoreRestAssured() {
        RestAssured.reset();
    }

    @Test
    public void testSslClientWithCert() throws MalformedURLException, Exception {
        URL url = new URL("https://localhost:8444/ssl");
        RestAssured.given()
                .keyStore("/conf/client-keystore.jks", "secret")
                .and()
                .trustStore("/conf/truststore.jks", "secret")
                .get(url)
                .then()
                .statusCode(200).body(is("ssl"));
    }

    @ApplicationScoped
    static class MyBean {

        public void register(@Observes Router router) {
            router.get("/ssl").handler(rc -> {
                Assertions.assertThat(rc.request().connection().isSsl()).isTrue();
                Assertions.assertThat(rc.request().isSSL()).isTrue();
                Assertions.assertThat(rc.request().connection().sslSession()).isNotNull();
                Assertions.assertThatCode(() -> {
                    X509Certificate[] clientCertChain = rc.request().connection().sslSession().getPeerCertificateChain();
                    Assertions.assertThat(clientCertChain).isNotNull().isNotEmpty();
                }).doesNotThrowAnyException();
                rc.response().end("ssl");
            });
        }

    }

}
