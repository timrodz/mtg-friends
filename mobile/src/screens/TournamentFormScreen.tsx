import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  ScrollView,
  Switch,
  KeyboardAvoidingView,
  Platform,
} from "react-native";
import { useRoute, RouteProp, useNavigation } from "@react-navigation/native";
import {
  useTournament,
  useUpdateTournament,
  useCreateTournament,
} from "../hooks/useTournaments";
import { RootStackParamList } from "../navigation/types";
import { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useAuthStore } from "../store/authStore";

type FormRouteProp = RouteProp<RootStackParamList, "TournamentCreate">;
type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

const GAME_OPTIONS = [
  { label: "Magic: The Gathering", value: 1, code: "mtg" },
  { label: "Yu-Gi-Oh!", value: 2, code: "yugioh" },
  { label: "Pokémon", value: 3, code: "pokemon" },
];

const FORMAT_OPTIONS = [
  { label: "Commander (EDH)", value: "edh" },
  { label: "Standard", value: "standard" },
];

const STATUS_OPTIONS = [
  { label: "1. Open (registering)", value: "inactive" },
  { label: "2. In progress", value: "active" },
  { label: "3. Finished", value: "finished" },
];

const PAIRING_OPTIONS = [
  { label: "Swiss Rounds", value: "swiss" },
  { label: "Bubble Rounds", value: "bubble_rounds" },
];

export default function TournamentFormScreen() {
  const route = useRoute<FormRouteProp>();
  const navigation = useNavigation<NavigationProp>();
  const user = useAuthStore((state) => state.user);
  const id = route.params?.id;
  const isEditMode = !!id;

  const { data: response, isLoading: isLoadingTournament } = useTournament(
    id as number
  );
  const updateMutation = useUpdateTournament();
  const createMutation = useCreateTournament();

  const isPending = updateMutation.isPending || createMutation.isPending;

  // State
  const [name, setName] = useState("");
  const [location, setLocation] = useState("");
  const [date, setDate] = useState("");
  const [description, setDescription] = useState("");
  const [gameId, setGameId] = useState(1);
  const [format, setFormat] = useState("edh");
  const [status, setStatus] = useState("inactive");
  const [roundLength, setRoundLength] = useState("60");
  const [roundCount, setRoundCount] = useState("4");
  const [subformat, setSubformat] = useState("swiss");
  const [isTopCut4, setIsTopCut4] = useState(false);
  const [initialParticipants, setInitialParticipants] = useState("");

  useEffect(() => {
    if (isEditMode && response?.data) {
      const t = response.data;
      setName(t.name || "");
      setLocation(t.location || "");
      setDate(t.date ? new Date(t.date).toISOString().split("T")[0] : "");
      setDescription(t.description_raw || "");
      setGameId(t.game_id || 1);
      setFormat(t.format || "edh");
      setStatus(t.status || "inactive");
      setRoundLength((t.round_length_minutes || 60).toString());
      setRoundCount((t.round_count || 4).toString());
      setSubformat(t.subformat || "swiss");
      setIsTopCut4(!!t.is_top_cut_4);
    }
  }, [response, isEditMode]);

  const handleSubmit = () => {
    if (!name || name.length < 5) {
      Alert.alert("Error", "Name must be at least 5 characters");
      return;
    }

    const payload = {
      name,
      location: location || "TBD",
      date: date ? new Date(date).toISOString() : new Date().toISOString(),
      description_raw: description,
      game_id: gameId,
      format,
      status,
      round_length_minutes: parseInt(roundLength, 10) || 60,
      round_count: parseInt(roundCount, 10) || 4,
      subformat,
      is_top_cut_4: isTopCut4,
      user_id: user?.id,
      initial_participants: isEditMode ? "" : initialParticipants,
    };

    if (isEditMode) {
      updateMutation.mutate(
        { id: id as number, data: payload },
        {
          onSuccess: () => {
            Alert.alert("Success", "Tournament updated");
            navigation.goBack();
          },
          onError: (error: any) => {
            Alert.alert(
              "Error",
              error.message || "Failed to update tournament"
            );
          },
        }
      );
    } else {
      createMutation.mutate(payload, {
        onSuccess: (response) => {
          Alert.alert("Success", "Tournament created");
          if (response?.data?.id) {
            navigation.replace("TournamentDetail", { id: response.data.id });
          } else {
            navigation.goBack();
          }
        },
        onError: (error: any) => {
          Alert.alert("Error", error.message || "Failed to create tournament");
        },
      });
    }
  };

  if (isEditMode && isLoadingTournament) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  const renderOptionList = (
    label: string,
    options: { label: string; value: any }[],
    currentValue: any,
    setter: (val: any) => void
  ) => (
    <View style={styles.section}>
      <Text style={styles.label}>{label}</Text>
      <View style={styles.optionsContainer}>
        {options.map((opt) => (
          <TouchableOpacity
            key={opt.value.toString()}
            style={[
              styles.optionButton,
              currentValue === opt.value && styles.optionButtonActive,
            ]}
            onPress={() => setter(opt.value)}
          >
            <Text
              style={[
                styles.optionText,
                currentValue === opt.value && styles.optionTextActive,
              ]}
            >
              {opt.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      style={{ flex: 1 }}
    >
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.contentContainer}
      >
        <Text style={styles.headerTitle}>
          {isEditMode ? `Edit ${name}` : "Create Tournament"}
        </Text>

        {renderOptionList("Game", GAME_OPTIONS, gameId, setGameId)}
        {renderOptionList("Format", FORMAT_OPTIONS, format, setFormat)}

        <View style={styles.section}>
          <Text style={styles.label}>Name</Text>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder="Tournament name"
          />
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Location</Text>
          <TextInput
            style={styles.input}
            value={location}
            onChangeText={setLocation}
            placeholder="Location"
          />
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Date (YYYY-MM-DD)</Text>
          <TextInput
            style={styles.input}
            value={date}
            onChangeText={setDate}
            placeholder="2023-12-31"
          />
        </View>

        {renderOptionList("Status", STATUS_OPTIONS, status, setStatus)}

        <View style={styles.section}>
          <Text style={styles.label}>Description</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            value={description}
            onChangeText={setDescription}
            multiline
            placeholder="Tournament details..."
          />
        </View>

        <View style={styles.row}>
          <View style={[styles.section, { flex: 1, marginRight: 10 }]}>
            <Text style={styles.label}>Round duration (Min)</Text>
            <TextInput
              style={styles.input}
              value={roundLength}
              onChangeText={setRoundLength}
              keyboardType="numeric"
            />
          </View>
          <View style={[styles.section, { flex: 1 }]}>
            <Text style={styles.label}>Number of rounds</Text>
            <TextInput
              style={styles.input}
              value={roundCount}
              onChangeText={setRoundCount}
              keyboardType="numeric"
            />
          </View>
        </View>

        {renderOptionList(
          "Round pairing algorithm",
          PAIRING_OPTIONS,
          subformat,
          setSubformat
        )}

        {gameId === 1 && (
          <View style={styles.switchContainer}>
            <Text style={styles.label}>Top Cut 4</Text>
            <Switch
              value={isTopCut4}
              onValueChange={setIsTopCut4}
              trackColor={{ false: "#767577", true: "#81b0ff" }}
              thumbColor={isTopCut4 ? "#007AFF" : "#f4f3f4"}
            />
          </View>
        )}

        {!isEditMode && (
          <View style={styles.section}>
            <Text style={styles.label}>Participants (one per line)</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={initialParticipants}
              onChangeText={setInitialParticipants}
              multiline
              placeholder="Player 1&#10;Player 2&#10;Player 3&#10;Player 4"
            />
          </View>
        )}

        <TouchableOpacity
          style={styles.saveButton}
          onPress={handleSubmit}
          disabled={isPending}
        >
          {isPending ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.saveText}>
              {isEditMode ? "Save Changes" : "Create Tournament"}
            </Text>
          )}
        </TouchableOpacity>

        <View style={{ height: 40 }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f8f9fa",
  },
  contentContainer: {
    padding: 20,
  },
  center: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: "bold",
    color: "#6200ee",
    marginBottom: 20,
  },
  section: {
    marginBottom: 15,
  },
  label: {
    fontSize: 14,
    fontWeight: "600",
    color: "#444",
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: "#ddd",
    padding: 12,
    borderRadius: 8,
    backgroundColor: "#fff",
    fontSize: 16,
  },
  textArea: {
    height: 100,
    textAlignVertical: "top",
  },
  row: {
    flexDirection: "row",
  },
  optionsContainer: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  optionButton: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "#ddd",
    backgroundColor: "#fff",
    marginBottom: 8,
  },
  optionButtonActive: {
    backgroundColor: "#6200ee",
    borderColor: "#6200ee",
  },
  optionText: {
    color: "#666",
    fontSize: 13,
  },
  optionTextActive: {
    color: "#fff",
    fontWeight: "600",
  },
  switchContainer: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 10,
    marginBottom: 20,
  },
  saveButton: {
    backgroundColor: "#6200ee",
    padding: 16,
    borderRadius: 12,
    alignItems: "center",
    marginTop: 10,
    shadowColor: "#6200ee",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 5,
    elevation: 8,
  },
  saveText: {
    color: "#fff",
    fontWeight: "bold",
    fontSize: 18,
  },
});
