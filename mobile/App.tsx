import { StatusBar } from "expo-status-bar";
import React, { useState } from "react";
import { StyleSheet, View } from "react-native";
import LoginScreen from "./src/screens/LoginScreen";
import TournamentListScreen from "./src/screens/TournamentListScreen";

export default function App() {
  const [token, setToken] = useState<string | null>(null);

  return (
    <View style={styles.container}>
      {token ? (
        <TournamentListScreen token={token} />
      ) : (
        <LoginScreen onLoginSuccess={setToken} />
      )}
      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
});
