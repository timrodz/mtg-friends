import React, { useEffect } from "react";
import { StatusBar } from "expo-status-bar";
import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { QueryClientProvider } from "@tanstack/react-query";
import { SafeAreaProvider } from "react-native-safe-area-context";

import { useAuthStore } from "./src/store/authStore";
import { queryClient } from "./src/api/queryClient";
import { RootStackParamList } from "./src/navigation/types";

import LoginScreen from "./src/screens/LoginScreen";
import TournamentListScreen from "./src/screens/TournamentListScreen";
import TournamentDetailScreen from "./src/screens/TournamentDetailScreen";
import TournamentFormScreen from "./src/screens/TournamentFormScreen";
import ParticipantCreateScreen from "./src/screens/ParticipantCreateScreen";
import ParticipantEditScreen from "./src/screens/ParticipantEditScreen";
import RoundDetailScreen from "./src/screens/RoundDetailScreen";
import { ActivityIndicator, View } from "react-native";

const Stack = createNativeStackNavigator<RootStackParamList>();

function AppNavigator() {
  const { isAuthenticated, isLoading, loadToken } = useAuthStore();

  useEffect(() => {
    loadToken();
  }, []);

  if (isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator id="RootStack">
        <Stack.Screen
          name="TournamentList"
          component={TournamentListScreen}
          options={{ title: "Tournaments" }}
        />
        <Stack.Screen
          name="TournamentCreate"
          component={TournamentFormScreen}
          options={{ title: "Create Tournament" }}
        />
        <Stack.Screen
          name="TournamentDetail"
          component={TournamentDetailScreen}
          options={{ title: "Tournament Details" }}
        />
        <Stack.Screen
          name="TournamentEdit"
          component={TournamentFormScreen}
          options={{ title: "Edit Tournament" }}
        />
        <Stack.Screen
          name="ParticipantCreate"
          component={ParticipantCreateScreen}
          options={{ title: "Add Participant" }}
        />
        <Stack.Screen
          name="Login"
          component={LoginScreen}
          options={{ title: "Login" }}
        />
        <Stack.Screen
          name="ParticipantEdit"
          component={ParticipantEditScreen}
          options={{ title: "Edit Participant" }}
        />
        <Stack.Screen
          name="RoundDetail"
          component={RoundDetailScreen}
          options={{ title: "Round Details" }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <AppNavigator />
        <StatusBar style="auto" />
      </QueryClientProvider>
    </SafeAreaProvider>
  );
}
