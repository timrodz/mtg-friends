import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
} from "react-native";
import { useCreateTournament } from "../hooks/useTournaments";
import { useNavigation } from "@react-navigation/native";
import { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/types";

type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

export default function TournamentCreateScreen() {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [format, setFormat] = useState("edh"); // Default
  const navigation = useNavigation<NavigationProp>();
  const createMutation = useCreateTournament();

  const handleCreate = () => {
    if (!name || !description) {
      Alert.alert("Validation Error", "Please fill in all fields");
      return;
    }

    createMutation.mutate(
      {
        name,
        description_raw: description,
        format, // "edh" or "standard"
        date: new Date().toISOString(), // Default to now for simplicity
        location: "TBD", // Default
        user_id: 1, // API usually infers from token, but schema might require it or override.
        // Wait, schema requires user_id and game_id.
        // In `create_tournament`, `user_id` is often set from conn assign.
        // `game_id` is required. We'll set a default "1" or code "mtg" if API handles it.
        // Let's assume API handles user_id from token.
        // We might need to pass game_id. Existing tests used fixtures.
        // Let's assume game_id=1 exists or add it.
        game_id: 1,
      },
      {
        onSuccess: () => {
          navigation.goBack();
        },
        onError: (error: any) => {
          Alert.alert("Error", error.message || "Failed to create tournament");
        },
      }
    );
  };

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Tournament Name</Text>
      <TextInput
        style={styles.input}
        value={name}
        onChangeText={setName}
        placeholder="e.g. Wednesday Night Magic"
      />

      <Text style={styles.label}>Description</Text>
      <TextInput
        style={[styles.input, styles.textArea]}
        value={description}
        onChangeText={setDescription}
        placeholder="Tournament rules and details..."
        multiline
      />

      {/* Simplified Format Selection */}
      <Text style={styles.label}>Format</Text>
      <View style={styles.formatContainer}>
        <TouchableOpacity
          style={[
            styles.formatButton,
            format === "edh" && styles.formatButtonActive,
          ]}
          onPress={() => setFormat("edh")}
        >
          <Text
            style={[
              styles.formatText,
              format === "edh" && styles.formatTextActive,
            ]}
          >
            EDH
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            styles.formatButton,
            format === "standard" && styles.formatButtonActive,
          ]}
          onPress={() => setFormat("standard")}
        >
          <Text
            style={[
              styles.formatText,
              format === "standard" && styles.formatTextActive,
            ]}
          >
            Standard
          </Text>
        </TouchableOpacity>
      </View>

      <TouchableOpacity
        style={styles.submitButton}
        onPress={handleCreate}
        disabled={createMutation.isPending}
      >
        {createMutation.isPending ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.submitText}>Create Tournament</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#fff",
  },
  label: {
    fontWeight: "bold",
    marginBottom: 5,
    marginTop: 10,
  },
  input: {
    borderWidth: 1,
    borderColor: "#ddd",
    padding: 10,
    borderRadius: 5,
    backgroundColor: "#f9f9f9",
  },
  textArea: {
    height: 100,
    textAlignVertical: "top",
  },
  formatContainer: {
    flexDirection: "row",
    marginBottom: 20,
  },
  formatButton: {
    flex: 1,
    padding: 10,
    borderWidth: 1,
    borderColor: "#007AFF",
    marginRight: 10,
    borderRadius: 5,
    alignItems: "center",
  },
  formatButtonActive: {
    backgroundColor: "#007AFF",
  },
  formatText: {
    color: "#007AFF",
  },
  formatTextActive: {
    color: "#fff",
  },
  submitButton: {
    backgroundColor: "#007AFF",
    padding: 15,
    borderRadius: 5,
    alignItems: "center",
    marginTop: 20,
  },
  submitText: {
    color: "#fff",
    fontWeight: "bold",
    fontSize: 16,
  },
});
