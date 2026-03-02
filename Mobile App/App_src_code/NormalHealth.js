
import React from 'react';

//import all the components we are going to use
import { StyleSheet, View, Text, SafeAreaView, Image, Button, Alert, Dimensions } from 'react-native';
const { width, height } = Dimensions.get("screen");

const App = (props) => {
  return (

    <View style={styles.container}>
      <Text style={{ textAlign: 'center', fontSize: 30, bottom: 50, fontWeight: 'bold', color: "green" }}>ASSAULT DETECTION</Text>
      <Image
        source={require('./safe.jpeg')}
        style={{ width: width / 2 + 40, height: height / 3, margin: 16 }}
      />
      <Text style={{ textAlign: 'center', fontSize: 27, fontWeight: 'bold', marginTop: 25, color: "green" }}>NO ASSAULT DETECTED</Text>

    </View>
  );
};
const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'white',
    flexDirection: 'column'
  },
});
export default App;