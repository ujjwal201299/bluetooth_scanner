package io.stratosfy.stratosfy_scanner.helpers

import android.content.Context
import android.util.Base64
import io.flutter.Log
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import org.eclipse.paho.client.mqttv3.*
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence
import java.io.IOException
import java.security.KeyFactory
import java.security.NoSuchAlgorithmException
import java.security.spec.InvalidKeySpecException
import java.security.spec.PKCS8EncodedKeySpec
import java.util.*

class SnowMMqttClient(context: Context) {
    //TODO: Change these parameters
    private var privateKeyPath: String? = null
    private val registryId = "beacon-registry"
    private  var deviceId :String = ""
    private val projectId = "beaconm-c04b0"
    private val region = "us-central1"
    private val publishTopic = "/devices/$deviceId/events"
    private val clientId = ("projects/" + projectId + "/locations/" + region + "/registries/" + registryId
            + "/devices/" + deviceId)

    @Throws(MqttException::class, InterruptedException::class, NoSuchAlgorithmException::class, InvalidKeySpecException::class)
    fun init(deviceId: String, message: String) {
        this.deviceId = deviceId
        val mqttConnectOptions = MqttConnectOptions()
        mqttConnectOptions.mqttVersion = MqttConnectOptions.MQTT_VERSION_3_1_1
        val sslProps = Properties()
        sslProps.setProperty("com.ibm.ssl.protocol", "TLSv1.2")
        mqttConnectOptions.sslProperties = sslProps
        mqttConnectOptions.userName = "unused"
        mqttConnectOptions.password = createJwtRsa(projectId, privateKeyPath).toCharArray()
        mqttConnectOptions.isAutomaticReconnect = true
        mqttConnectOptions.isCleanSession = false
        val serverUri = "ssl://mqtt.googleapis.com:8883"
        val client = MqttClient(serverUri, clientId, MemoryPersistence())

        // Both connect and publish operations may fail. If they do, allow retries but
        // with an
        // exponential backoff time period.
        val initialConnectIntervalMillis = 500L
        val maxConnectIntervalMillis = 6000L
        val maxConnectRetryTimeElapsedMillis = 900000L
        val intervalMultiplier = 1.5f
        var retryIntervalMs = initialConnectIntervalMillis
        var totalRetryTimeMs: Long = 0
        while (!client.isConnected && totalRetryTimeMs < maxConnectRetryTimeElapsedMillis) {
            try {
                client.connect(mqttConnectOptions)
                Log.d("MqttHelper", "connected to server")
            } catch (e: MqttException) {
                val reason = e.reasonCode

                // If the connection is lost or if the server cannot be connected, allow
                // retries, but with
                // exponential backoff.
                println("An error occurred: " + e.message)
                if (reason == MqttException.REASON_CODE_CONNECTION_LOST.toInt() || reason == MqttException.REASON_CODE_SERVER_CONNECT_ERROR.toInt()) {
                    println("Retrying in " + retryIntervalMs / 1000.0 + " seconds.")
                    Thread.sleep(retryIntervalMs)
                    totalRetryTimeMs += retryIntervalMs
                    retryIntervalMs *= intervalMultiplier.toLong()
                    if (retryIntervalMs > maxConnectIntervalMillis) {
                        retryIntervalMs = maxConnectIntervalMillis
                    }
                } else {
                    throw e
                }
            }
        }
        this.client = client
        attachCallback(client)
        publishMessage(message)
    }

    private var client: MqttClient? = null
    private fun publishMessage(_message: String) {
        try {
            val message = MqttMessage()
            message.payload = _message.toByteArray()
            client!!.publish(publishTopic, message)
            Log.d("MqttHelper", "Message Published")
            if (!client!!.isConnected) {
                Log.d("MqttHelper", " messages in buffer.")
            }
        } catch (e: MqttException) {
            System.err.println("Error Publishing: " + e.message)
            e.printStackTrace()
        }
    }

    companion object {
        @Throws(NoSuchAlgorithmException::class, InvalidKeySpecException::class)
        private fun createJwtRsa(projectId: String, byteBuffer: String?): String {
            val ONE_MINUTE_IN_MILLIS: Long = 60000 // millisecs
            val d = Calendar.getInstance()
            val t = d.timeInMillis
            val now = Date()
            val after = Date(t + 20 * ONE_MINUTE_IN_MILLIS)
            // Create a JWT to authenticate this device. The device will be disconnected
            // after the token
            // expires, and will have to reconnect with a new token. The audience field
            // should always be set
            // to the GCP project id.
            val jwtBuilder = Jwts.builder().setIssuedAt(now).setExpiration(after).setAudience(projectId)
            val encoded = Base64.decode(byteBuffer, Base64.DEFAULT)
            val spec = PKCS8EncodedKeySpec(encoded)
            val kf = KeyFactory.getInstance("RSA")
            return jwtBuilder.signWith(SignatureAlgorithm.RS256, kf.generatePrivate(spec)).compact()
        }

        /**
         * Attaches the callback used when configuration changes occur.
         */
        private fun attachCallback(client: MqttClient) {
            val mCallback: MqttCallback = object : MqttCallback {
                override fun connectionLost(cause: Throwable) {
                    Log.d("MqttHelper", "Connection was lost because of \$cause")
                }

                override fun messageArrived(topic: String, message: MqttMessage) {
                    Log.d("MqttHelper", "Incoming message :" + Arrays.toString(message.payload))
                }

                override fun deliveryComplete(token: IMqttDeliveryToken) {
                    Log.d("MqttHelper", "Delivery completed :" + token.response)
                }
            }
            client.setCallback(mCallback)
        }
    }

    init {
        try {
            val `is` = context.assets.open("rsa_private.pem")
            val byteBuffer = ByteArray(`is`.available())
            `is`.read(byteBuffer)
            `is`.close()
            privateKeyPath = String(byteBuffer)
            privateKeyPath = privateKeyPath!!.replace("-----BEGIN PRIVATE KEY-----", "")
            privateKeyPath = privateKeyPath!!.replace("-----END PRIVATE KEY-----", "")
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }
}