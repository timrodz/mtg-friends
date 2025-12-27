import { RouteProp, useRoute } from "@react-navigation/native";
import React, { useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Modal,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { PairingType, ParticipantType } from "../api/types";
import { useRound, useUpdateRound } from "../hooks/useRounds";
import { useTournament } from "../hooks/useTournaments";
import { RootStackParamList } from "../navigation/types";
import { useAuthStore } from "../store/authStore";
import { formatRemainingTime } from "../utils/time";

type RoundDetailRouteProp = RouteProp<RootStackParamList, "RoundDetail">;

type SelectedTable = {
  table: number;
  players: PairingType[];
  active: boolean;
};
type ScoreMap = { [key: number]: string };

export default function RoundDetailScreen() {
  const route = useRoute<RoundDetailRouteProp>();
  const { tournamentId, roundNumber } = route.params;

  // Hooks
  const user = useAuthStore((state) => state.user);
  const { data: tournamentData } = useTournament(tournamentId);
  const {
    data: response,
    isLoading,
    error,
  } = useRound(tournamentId, roundNumber);
  const updateRoundMutation = useUpdateRound();

  // State
  const [modalVisible, setModalVisible] = useState(false);
  const [selectedTable, setSelectedTable] = useState<SelectedTable>(null);
  const [scores, setScores] = useState<ScoreMap>({});
  const [timer, setTimer] = useState("00:00");

  const isOwner = user?.id === tournamentData?.data?.user_id;

  const pairings: SelectedTable[] = useMemo(() => {
    if (isLoading || !response?.data?.pairings) return [];

    // Group by pairing number (table number)
    const grouped = response.data.pairings.reduce(
      (acc: PairingType, pairing: PairingType) => {
        // p.number is the table/pod number
        if (!acc[pairing.number]) {
          acc[pairing.number] = [];
        }
        acc[pairing.number].push(pairing);
        return acc;
      },
      {}
    );

    // Convert to array of tables
    return Object.keys(grouped)
      .map((tableNumber) => ({
        table: parseInt(tableNumber),
        players: grouped[tableNumber],
        // Active if any pairing in the pod is active (treat null/undefined as active)
        active: grouped[tableNumber].some(
          (pairing: PairingType) => pairing.active !== false
        ),
      }))
      .sort((a, b) => a.table - b.table);
  }, [response, isLoading]);

  // Timer logic
  useEffect(() => {
    if (!response?.data?.inserted_at || response.data.is_complete) return;

    const interval = setInterval(() => {
      const formattedTime = formatRemainingTime(response.data.inserted_at);
      setTimer(formattedTime);
    }, 1000);

    return () => clearInterval(interval);
  }, [response?.data?.inserted_at, response?.data?.is_complete]);

  const handleOpenModal = (tableItem: SelectedTable) => {
    setSelectedTable(tableItem);
    const initialScores: ScoreMap = {};
    tableItem.players.forEach((pairing: PairingType) => {
      initialScores[pairing.participant_id] = (pairing.points || 0).toString();
    });
    setScores(initialScores);
    setModalVisible(true);
  };

  const handleScoreChange = (participantId: number, text: string) => {
    setScores((prev) => ({ ...prev, [participantId]: text }));
  };

  const handleSubmitResults = () => {
    if (!selectedTable) return;

    // Validate scores are numbers
    const results = selectedTable.players.map((participant: PairingType) => {
      const scoreStr = scores[participant.participant_id] || "0";
      const points = parseInt(scoreStr, 10);
      return {
        participant_id: participant.participant_id,
        points: isNaN(points) ? 0 : points,
      };
    });

    updateRoundMutation.mutate(
      {
        tournamentId,
        roundNumber,
        results,
      },
      {
        onSuccess: () => {
          setModalVisible(false);
          setSelectedTable(null);
          Alert.alert("Success", "Results submitted!");
        },
        onError: (err: any) => {
          Alert.alert("Error", err.message || "Failed to submit results");
        },
      }
    );
  };

  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>Failed to load round details.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.headerContainer}>
        <Text style={styles.header}>Round {roundNumber + 1}</Text>
        <View
          style={[
            styles.statusBadge,
            response?.data?.is_complete
              ? styles.statusFinished
              : styles.statusActive,
          ]}
        >
          <Text style={styles.statusText}>
            {response?.data?.is_complete ? "Finished" : "In Progress"}
          </Text>
        </View>
      </View>

      {!response?.data?.is_complete && (
        <Text style={styles.timerText}>Round time: {timer}</Text>
      )}

      <FlatList
        data={pairings}
        keyExtractor={(item) => item.table.toString()}
        renderItem={({ item }) => (
          <View style={styles.matchCard}>
            <View style={styles.matchHeader}>
              <Text style={styles.tableNumber}>Table {item.table}</Text>
              {!item.active && (
                <Text style={styles.completedBadge}>Completed</Text>
              )}
            </View>

            <View style={styles.playersContainer}>
              {item.players.map((participant: PairingType, index: number) => (
                <View key={participant.id} style={styles.playerRow}>
                  <Text style={styles.playerName}>
                    {participant.participant?.name || "Unknown Player"}
                  </Text>
                  <Text style={styles.playerPoints}>
                    {participant.points} pts
                  </Text>
                  {/* VS separator if not the last player (assuming 2 players usually) */}
                  {index < item.players.length - 1 && (
                    <Text style={styles.vsText}>VS</Text>
                  )}
                </View>
              ))}
              {item.players.length === 1 && (
                <Text style={styles.byeText}>BYE</Text>
              )}
            </View>

            {isOwner && item.active && (
              <TouchableOpacity
                style={styles.assignButton}
                onPress={() => handleOpenModal(item)}
              >
                <Text style={styles.assignButtonText}>Assign pod results</Text>
              </TouchableOpacity>
            )}
          </View>
        )}
        ListEmptyComponent={
          <Text style={styles.emptyText}>
            No pairings found for this round.
          </Text>
        }
      />

      <Modal
        visible={modalVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalContainer}>
          <Text style={styles.modalHeader}>
            Table {selectedTable?.table} Results
          </Text>
          <Text style={styles.modalSubHeader}>
            Enter points for each player
          </Text>

          {selectedTable?.players.map((participant: PairingType) => (
            <View key={participant.id} style={styles.inputRow}>
              <Text style={styles.inputLabel}>
                {participant.participant?.name}
              </Text>
              <TextInput
                style={styles.scoreInput}
                keyboardType="numeric"
                value={scores[participant.participant_id]}
                onChangeText={(text) =>
                  handleScoreChange(participant.participant_id, text)
                }
              />
            </View>
          ))}

          <View style={styles.modalButtons}>
            <TouchableOpacity
              style={[styles.modalButton, styles.cancelButton]}
              onPress={() => setModalVisible(false)}
            >
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.modalButton, styles.submitButton]}
              onPress={handleSubmitResults}
              disabled={updateRoundMutation.isPending}
            >
              {updateRoundMutation.isPending ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.submitButtonText}>Submit Changes</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f5f5f5",
    padding: 15,
  },
  center: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  headerContainer: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 5,
  },
  header: {
    fontSize: 24,
    fontWeight: "bold",
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    overflow: "hidden",
  },
  statusActive: {
    backgroundColor: "#e0f7fa",
  },
  statusFinished: {
    backgroundColor: "#e8f5e9",
  },
  statusText: {
    fontWeight: "bold",
    color: "#006064", // Default for active, override for finished needed?
    fontSize: 12,
  },
  timerText: {
    fontSize: 24,
    color: "#333",
    marginBottom: 20,
    marginTop: 5,
    fontWeight: "bold",
    fontVariant: ["tabular-nums"],
  },
  matchCard: {
    backgroundColor: "white",
    borderRadius: 10,
    padding: 15,
    marginBottom: 10,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  matchHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 10,
  },
  tableNumber: {
    fontSize: 14,
    fontWeight: "bold",
    color: "#666",
    textTransform: "uppercase",
  },
  completedBadge: {
    fontSize: 12,
    color: "green",
    fontWeight: "bold",
    backgroundColor: "#e0ffe0",
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 8,
  },
  playersContainer: {
    flexDirection: "column",
    alignItems: "center",
  },
  playerRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    width: "100%",
    paddingVertical: 5,
  },
  playerName: {
    fontSize: 16,
    fontWeight: "500",
    flex: 1,
  },
  playerPoints: {
    fontSize: 16,
    fontWeight: "bold",
    color: "#333",
  },
  vsText: {
    fontSize: 12,
    fontWeight: "bold",
    color: "#999",
    marginTop: 2,
    marginBottom: 2,
    alignSelf: "center",
  },
  byeText: {
    color: "#888",
    fontStyle: "italic",
    marginTop: 4,
  },
  assignButton: {
    backgroundColor: "#6200ee", // Purple-ish
    paddingVertical: 10,
    borderRadius: 8,
    alignItems: "center",
    marginTop: 15,
  },
  assignButtonText: {
    color: "#fff",
    fontWeight: "bold",
    fontSize: 16,
  },
  errorText: {
    color: "red",
    fontSize: 16,
  },
  emptyText: {
    textAlign: "center",
    color: "#888",
    marginTop: 20,
  },
  // Modal Styles
  modalContainer: {
    flex: 1,
    padding: 20,
    paddingTop: 50,
    backgroundColor: "#fff",
  },
  modalHeader: {
    fontSize: 22,
    fontWeight: "bold",
    marginBottom: 10,
    textAlign: "center",
  },
  modalSubHeader: {
    fontSize: 16,
    color: "#666",
    marginBottom: 20,
    textAlign: "center",
  },
  inputRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 15,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: "#eee",
  },
  inputLabel: {
    fontSize: 18,
    flex: 1,
    fontWeight: "500",
  },
  scoreInput: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    padding: 10,
    width: 80,
    textAlign: "center",
    fontSize: 18,
  },
  modalButtons: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 30,
  },
  modalButton: {
    flex: 1,
    padding: 15,
    borderRadius: 8,
    alignItems: "center",
  },
  cancelButton: {
    backgroundColor: "#eee",
    marginRight: 10,
  },
  cancelButtonText: {
    color: "#333",
    fontSize: 16,
    fontWeight: "600",
  },
  submitButton: {
    backgroundColor: "#6200ee",
    marginLeft: 10,
  },
  submitButtonText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "600",
  },
});
