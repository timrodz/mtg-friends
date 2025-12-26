import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
} from "react-native";
import { useRoute, RouteProp, useNavigation } from "@react-navigation/native";
import { RootStackParamList } from "../navigation/types";
import { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useUpdateParticipant } from "../hooks/useParticipants";

type EditParticipantRouteProp = RouteProp<
  RootStackParamList,
  "ParticipantEdit"
>;
type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

export default function ParticipantEditScreen() {
  const route = useRoute<EditParticipantRouteProp>();
  const navigation = useNavigation<NavigationProp>();
  const { tournamentId, participant } = route.params;

  const [name, setName] = useState(participant.name);
  const [decklist, setDecklist] = useState(participant.decklist || "");
  const [error, setError] = useState("");

  const updateParticipantMutation = useUpdateParticipant();

  const handleSubmit = async () => {
    if (!name.trim()) {
      setError("Name is required");
      return;
    }
    setError("");

    updateParticipantMutation.mutate(
      {
        tournamentId,
        participantId: participant.id,
        data: { name, decklist },
      },
      {
        onSuccess: () => {
          navigation.goBack();
        },
        onError: (err: any) => {
          setError(err.message || "Failed to update participant");
        },
      }
    );
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.header}>Edit Participant</Text>

      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      <View style={styles.formGroup}>
        <Text style={styles.label}>Name *</Text>
        <TextInput
          style={styles.input}
          value={name}
          onChangeText={setName}
          placeholder="Enter participant name"
        />
      </View>

      <View style={styles.formGroup}>
        <Text style={styles.label}>Decklist (Optional)</Text>
        <TextInput
          style={styles.input}
          value={decklist}
          onChangeText={setDecklist}
          placeholder="Paste decklist URL or text"
          inputMode="url"
        />
      </View>

      <TouchableOpacity
        style={styles.saveButton}
        onPress={handleSubmit}
        disabled={updateParticipantMutation.isPending}
      >
        {updateParticipantMutation.isPending ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.saveButtonText}>Save Changes</Text>
        )}
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 20,
    backgroundColor: "#fff",
    flexGrow: 1,
  },
  header: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 20,
    textAlign: "center",
  },
  formGroup: {
    marginBottom: 15,
  },
  label: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 5,
    color: "#333",
  },
  input: {
    borderWidth: 1,
    borderColor: "#ddd",
    padding: 12,
    borderRadius: 8,
    fontSize: 16,
    backgroundColor: "#f9f9f9",
  },
  saveButton: {
    backgroundColor: "#007AFF",
    padding: 15,
    borderRadius: 8,
    alignItems: "center",
    marginTop: 10,
  },
  saveButtonText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "bold",
  },
  errorText: {
    color: "red",
    marginBottom: 15,
    textAlign: "center",
  },
});
