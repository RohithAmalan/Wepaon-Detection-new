import React, { useState, useEffect} from 'react'
import { StyleSheet, Text, View, TextInput, TouchableOpacity, Dimensions } from 'react-native';
import NormalHealth from "./NormalHealth";
import AbnormalHealth from "./AbnormalHealth";
import LinearGradient from 'react-native-linear-gradient';
import AsyncStorage from '@react-native-async-storage/async-storage';
import MQTT from 'react-native-mqtt-new';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import PushNotification from 'react-native-push-notification';

export default function App(props) {
  const [flag, setflag] = useState(0);
  const [usernameentered, setusernameentered] = useState("");
  const [passwordentered, setpasswordentered] = useState("");
  const [ipaddress, setipaddress] = useState("");
  const [NotiTopic, setNotiTopic] = useState("");
  const [Shop_Topic, setShop_Topic] = useState("");
  const [TakeAction, setTakeAction] = useState("");
  const { width, height } = Dimensions.get("screen");
  const [notification_mobile_value, setnotification_mobile_value] = useState(
    '',
  );

  useEffect(() => {
    // AsyncStorage.clear()
  

    PushNotification.configure({
      // (optional) Called when Token is generated (iOS and Android)

      onRegister: function (token) {
        console.log(token.token);
        setnotification_mobile_value(token.token)
        // self.setState({
        //   tokenvalue: token
        // });

        // testing(token)
      },

      // (required) Called when a remote or local notification is opened or received
      onNotification: function (notification) {
        console.log('NOTIFICATION:', notification);

        // process the notification
        // self._addDataToList(notification);
        // required on iOS only (see fetchCompletionHandler docs: https://github.com/react-native-community/react-native-push-notification-ios)
        // notification.finish(PushNotificationIOS.FetchResult.NoData);
      },
      // ANDROID ONLY: GCM or FCM Sender ID (product_number) (optional - not required for local notifications, but is need to receive remote push notifications)
      senderID: '681967282456',

      // IOS ONLY (optional): default: all - Permissions to register.
      permissions: {
        alert: true,
        badge: true,
        sound: true,
      },

      // Should the initial notification be popped automatically
      // default: true
      popInitialNotification: true,

      /**
       * (optional) default: true
       * - Specified if permissions (ios) and token (android and ios) will requested or not,
       * - if not, you must call PushNotificationsHandler.requestPermissions() later
       */
      requestPermissions: true,
    });
  }, [flag]);
  function login() {

    if (ipaddress !== ""  && TakeAction !== "" && Shop_Topic !== "" && NotiTopic !== "") {
      if (usernameentered == "") {
        alert("Please enter Username ")
      }
      else if (passwordentered == "") {
        alert("Please enter Password ")
      }


      else if (usernameentered == "1" && passwordentered == "1") {

        setflag(1)


        AsyncStorage.setItem("ipaddress", ipaddress)

        MQTT.createClient({
          uri: 'mqtt://broker.hivemq.com:1883',

          clientId: 'your_client_id'
        }).then(function (client) {
          client.on('closed', function () {
            // console.log('mqtt.event.closed');
          });
          client.on('error', function (msg) {

          });

          client.on('message', function (msg) {
            console.log('mqtt.event.message', msg);
            console.log(msg.data)
            console.log("********** substring*********")

            if (msg.data != "0") {

              if (flag == 0 || flag == 1) {
                setflag(2)

              }

            }




          })




          client.on('connect', function () {
            console.log('connected');
            client.subscribe(Shop_Topic, 0);
            client.publish(NotiTopic, notification_mobile_value, 0, false);

            console.log(notification_mobile_value)


          });

          client.connect();
        }).catch(function (err) {
          console.log(err);
        });
        // console.log (usernameentered)
        // console.log (passwordentered)

      }

      else {

        alert("Entered Username and Password is incorrect")
      }


    }

    else {

      alert("Please enter all the required details")

    }


  }

  const callback = (value) => {

    console.log("++++++++++++++++++++++++++" + value)

    // setfarmstatus(0)

    setflag(1)



  }


  if (flag == 0) {
    return (





      <KeyboardAwareScrollView

        enableAutomaticScroll
        extraScrollHeight={10}
        enableOnAndroid={true}
        extraHeight={Platform.select({ android: 200 })}
        style={{ flexGrow: 1 }}

      >

        <View style={styles.container}>

          <LinearGradient colors={['#3dcc8c','#42f5a4', '#23ad6f']} style={{ flex: 1, height: height, justifyContent: 'center', alignItems: 'center' }}>

            <Text style={styles.logo}>WEAPON DETECTION</Text>
            <View style={styles.inputView} >
              <TextInput
                style={styles.inputText}
                placeholder="Username"
                placeholderTextColor="grey"
                onChangeText={text => setusernameentered(text)} />
            </View>
            <View style={styles.inputView} >
              <TextInput
                secureTextEntry
                style={styles.inputText}
                placeholder="Password"
                placeholderTextColor="grey"
                onChangeText={text => setpasswordentered(text)} />
            </View>

            <View style={styles.inputView} >
              <TextInput
                keyboardType="numeric"
                style={styles.inputText}
                placeholder="IP address"
                placeholderTextColor="grey"
                onChangeText={text => setipaddress(text)} />
            </View>

         

            <View style={styles.inputView} >
              <TextInput
                style={styles.inputText}
                placeholder="Notification Topic"
                placeholderTextColor="grey"
                onChangeText={text => {
                  setTakeAction(text)
                  setNotiTopic(text)
                }



                } />
            </View>

            <View style={styles.inputView} >
              <TextInput
                style={styles.inputText}
                placeholder="Shop Topic"
                placeholderTextColor="grey"
                onChangeText={text => setShop_Topic(text)} />
            </View>

          

            <TouchableOpacity style={styles.loginBtn}
              onPress={login}
            >
              <Text style={styles.loginText}>LOGIN</Text>
            </TouchableOpacity>

          </LinearGradient>
        </View>

      </KeyboardAwareScrollView>


    );

  }



  else if (flag == 1) {

    return (

      <NormalHealth
      />
    )
  }

  else if (flag == 2) {

    return (

      <AbnormalHealth videourl={ipaddress} callback={callback} takeactiontopic={TakeAction} />
    )
  }


}

const styles = StyleSheet.create({
  container: {
    flex: 1,

  },
  logo: {
    fontWeight: "bold",
    fontSize: 27,
    color: "white",
    marginBottom: 50
  },
  inputView: {
    width: "80%",
    backgroundColor: "white",
    borderRadius: 10,
    height: 50,
    marginBottom: 20,
    justifyContent: "center",
    padding: 20
  },
  inputText: {
    height: 50,
    color: "black",
    fontSize: 18
  },
  forgot: {
    color: "white",
    fontSize: 11
  },
  loginBtn: {
    width: "80%",
    backgroundColor: "#0b99a3",
    borderRadius: 10,
    height: 50,
    alignItems: "center",
    justifyContent: "center",
    marginTop: 40,
    marginBottom: 10
  },
  loginText: {
    color: "white",
    fontWeight: 'bold',
    fontSize: 20
  },
  linearGradient: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
