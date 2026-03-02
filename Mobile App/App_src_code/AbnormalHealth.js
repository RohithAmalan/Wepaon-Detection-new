import React, { Component, useState, useEffect } from 'react'
import { StyleSheet, View, Text, Alert, Dimensions, Switch, TouchableOpacity, Image } from 'react-native'
import { WebView } from 'react-native-webview';
import MQTT from 'react-native-mqtt-new';

const windowWidth = Dimensions.get('screen').width;
const windowHeight = Dimensions.get('screen').height;

export default function App(props) {


  const onPress = () => {

    props.callback(0)
  }

  const action = () => {

    MQTT.createClient({
      uri: 'mqtt://broker.hivemq.com:1883',
      clientId: 'your_client_id'
    }).then(function (client) {

      client.on('closed', function () {
        console.log('mqtt.event.closed');
      });

      client.on('error', function (msg) {
        console.log('mqtt.event.error', msg);
      });

      client.on('message', function (msg) {
        console.log('mqtt.event.message', msg);
      });

      client.on('connect', function () {
        console.log('connected');

        client.publish(props.takeactiontopic, "*", 1, false);
        client.disconnect();
      });

      client.connect();
    }).catch(function (err) {
      console.log(err);
    });

  }


  const action2 = () => {

    MQTT.createClient({
      uri: 'mqtt://broker.hivemq.com:1883',
      clientId: 'your_client_id'
    }).then(function (client) {

      client.on('closed', function () {
        console.log('mqtt.event.closed');
      });

      client.on('error', function (msg) {
        console.log('mqtt.event.error', msg);
      });

      client.on('message', function (msg) {
        console.log('mqtt.event.message', msg);
      });

      client.on('connect', function () {
        console.log('connected');

        client.publish(props.takeactiontopic, "$", 1, false);
        client.disconnect();





      });

      client.connect();
    }).catch(function (err) {
      console.log(err);
    });

  }






  TouchableOpacity.defaultProps = { activeOpacity: 0.8 };


  return (
    <View style={{ flex: 1, backgroundColor: 'white' }}>
      <WebView
        allowsFullscreenVideo
        allowsInlineMediaPlayback
        mediaPlaybackRequiresUserAction
        style={{ width: windowWidth + 190, height: windowHeight }}
        l        // source={{ uri: 'https://www.youtube.com/watch?v=DxIDKZHW3-E' }}
        source={{ uri: 'http://' + props.videourl + ':8000/' }}

      // source={{ uri: props.videourl}} 

      />
      <View
        style={{
          borderBottomColor: 'red',
          borderBottomWidth: 5,
        }}
      />

      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>




        <Image
          source={require('./theft.png')}
          style={{ width: 200, height: 150, resizeMode: 'center' }}
        />
        <Text style={{ textAlign: 'center', fontSize: 30, fontWeight: 'bold', marginTop: 20, color: "red" }}>WEAPON IS DETECTED {

        }
        </Text>

        <View style={{ flex: 1, flexDirection: 'row', justifyContent: 'center', alignItems: 'center' }}>


          <TouchableOpacity style={styles.loginBtn5}
            onPress={action}

          >
            <Text style={styles.loginText}>ALARM ON</Text>
          </TouchableOpacity>



          <TouchableOpacity style={styles.loginBtn5}
            onPress={action2}

          >
            <Text style={styles.loginText}>GATE CLOSE</Text>
          </TouchableOpacity>
        </View>
        <TouchableOpacity style={styles.loginBtn2}
          onPress={onPress}

        >
          <Text style={styles.loginText}>BACK TO NORMAL</Text>
        </TouchableOpacity>

      </View>


    </View>
  );

}

const styles = StyleSheet.create({
  screenContainer: {
    flex: 1,
    justifyContent: "center",
    padding: 16
  },
  appButtonContainer: {
    elevation: 8,
    backgroundColor: "#05b311",
    borderRadius: 15,
    paddingVertical: 15,
    paddingHorizontal: 15
  },
  appButtonText: {
    fontSize: 10,
    color: "#fff",
    fontWeight: "bold",
    alignSelf: "center",
    textTransform: "uppercase"
  },
  loginBtn: {
    width: "80%",
    backgroundColor: "red",
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
    padding: 10,
    margin: 10
  },

  loginBtn5: {
    backgroundColor: "red",
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
    padding: 10,
    margin: 10
  },
  loginBtn2: {
    width: "80%",
    backgroundColor: "green",
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
    padding: 10,
    margin: 10
  },
  loginText: {
    color: "white",
    fontWeight: 'bold',
    fontSize: 20
  },
});