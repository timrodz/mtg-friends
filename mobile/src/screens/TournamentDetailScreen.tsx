import React from "react";
import {
  View,
  Text,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
  ScrollView,
  Alert,
} from "react-native";
import RenderHTML from "react-native-render-html";
import { useWindowDimensions } from "react-native";
import { useRoute, RouteProp, useNavigation } from "@react-navigation/native";
import {
  useTournament,
  useDeleteParticipant,
  useCreateRound,
} from "../hooks/useTournaments";
import { RootStackParamList } from "../navigation/types";
import { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useAuthStore } from "../store/authStore";

type DetailRouteProp = RouteProp<RootStackParamList, "TournamentDetail">;
type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

export default function TournamentDetailScreen() {
  const { width } = useWindowDimensions();
  const route = useRoute<DetailRouteProp>();
  const navigation = useNavigation<NavigationProp>();
  const { id } = route.params;
  const { data: response, isLoading, error } = useTournament(id);
  const user = useAuthStore((state) => state.user);

  const deleteParticipantMutation = useDeleteParticipant();
  const createRoundMutation = useCreateRound();

  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  if (error || !response?.data) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>Failed to load tournament details.</Text>
      </View>
    );
  }

  const tournament = response.data;
  const participants = tournament.participants || [];
  const rounds = tournament.rounds || [];
  const isOwner = user?.id === tournament.user_id;

  const handleStartRound = () => {
    const isLastRound = rounds.length + 1 === tournament.round_count;
    Alert.alert(
      isLastRound ? "Start Last Round?" : "Start Next Round?",
      isLastRound
        ? "This will generate pairings for the final round of the tournament."
        : "This will generate pairings for the next round.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Start",
          onPress: () => {
            createRoundMutation.mutate(id, {
              onSuccess: (data) => {
                if (data?.data?.number !== undefined) {
                  navigation.navigate("RoundDetail", {
                    tournamentId: id,
                    roundNumber: data.data.number,
                  });
                } else {
                  Alert.alert("Success", "Round started!");
                }
              },
              onError: (err: any) => {
                Alert.alert("Error", err.message || "Failed to start round");
              },
            });
          },
        },
      ]
    );
  };

  const handleDeleteParticipant = (participantId: number) => {
    Alert.alert(
      "Remove Participant?",
      "Are you sure you want to remove this player?",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Remove",
          style: "destructive",
          onPress: () => {
            deleteParticipantMutation.mutate(
              { tournamentId: id, participantId },
              {
                onError: (err: any) => {
                  Alert.alert(
                    "Error",
                    err.message || "Failed to remove participant"
                  );
                },
              }
            );
          },
        },
      ]
    );
  };

  return (
    <ScrollView
      style={styles.root}
      contentContainerStyle={styles.container}
      contentInsetAdjustmentBehavior="automatic"
    >
      <View style={styles.header}>
        <View style={styles.titleContainer}>
          <Text style={styles.title}>{tournament.name}</Text>
          <Text style={styles.subtitle}>{tournament.format}</Text>
        </View>
        {isOwner && (
          <TouchableOpacity
            style={styles.editButton}
            onPress={() => navigation.navigate("TournamentEdit", { id })}
          >
            <Text style={styles.editButtonText}>Edit</Text>
          </TouchableOpacity>
        )}
      </View>

      <Text style={styles.sectionHeader}>Description</Text>
      <View style={styles.descriptionContainer}>
        <RenderHTML
          contentWidth={width - 40}
          source={{
            html:
              tournament.description_html ||
              `<p>${tournament.description_raw}</p>`,
          }}
          baseStyle={styles.descriptionBase}
          tagsStyles={{
            a: {
              color: "#007AFF",
              textDecorationLine: "underline",
            },
          }}
        />
      </View>

      <Text style={styles.sectionHeader}>Status: {tournament.status}</Text>

      <View style={styles.statsContainer}>
        <View style={styles.statBox}>
          <Text style={styles.statNumber}>{participants.length}</Text>
          <Text style={styles.statLabel}>Players</Text>
        </View>
        <View style={styles.statBox}>
          <Text style={styles.statNumber}>{rounds.length}</Text>
          <Text style={styles.statLabel}>Rounds</Text>
        </View>
      </View>

      <View style={styles.sectionRow}>
        <Text style={styles.sectionHeader}>Participants</Text>
        {isOwner && tournament.status === "inactive" && (
          <TouchableOpacity
            onPress={() =>
              navigation.navigate("ParticipantCreate", { tournamentId: id })
            }
          >
            <Text style={styles.actionLink}>+ Add</Text>
          </TouchableOpacity>
        )}
      </View>

      {participants.length === 0 ? (
        <Text style={styles.emptyText}>No participants added.</Text>
      ) : (
        participants.map((p: any) => (
          <View key={p.id} style={styles.listItem}>
            <View>
              <Text style={styles.listItemText}>{p.name}</Text>
              {p.points !== undefined && (
                <Text style={styles.listItemSub}>{p.points} pts</Text>
              )}
            </View>
            {isOwner && (
              <View style={{ flexDirection: "row", alignItems: "center" }}>
                <TouchableOpacity
                  onPress={() =>
                    navigation.navigate("ParticipantEdit", {
                      tournamentId: id,
                      participant: p,
                    })
                  }
                  style={styles.actionButton}
                >
                  <Text style={styles.actionLink}>Edit</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => handleDeleteParticipant(p.id)}
                  style={styles.deleteAction}
                >
                  <Text style={styles.deleteActionText}>Remove</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        ))
      )}

      <View style={styles.sectionRow}>
        <Text style={styles.sectionHeader}>Rounds</Text>
        {isOwner && tournament.status !== "finished" && (
          <TouchableOpacity
            onPress={() => {
              const latestRound = rounds[rounds.length - 1];
              if (latestRound && !latestRound.is_complete) {
                Alert.alert(
                  "Cannot Start Round",
                  "The current round is still in progress. Please finish all pod results first."
                );
              } else {
                handleStartRound();
              }
            }}
          >
            <Text
              style={[
                styles.actionLink,
                (rounds.length > 0 && !rounds[rounds.length - 1].is_complete) ||
                !tournament.has_enough_participants
                  ? styles.disabledLink
                  : null,
              ]}
            >
              {rounds.length + 1 === tournament.round_count
                ? "Start last round"
                : "Start Next Round"}
            </Text>
          </TouchableOpacity>
        )}
      </View>

      {!tournament.has_enough_participants && isOwner && (
        <Text style={styles.warningText}>
          Must have at least 4 participants before starting this tournament.
        </Text>
      )}

      {rounds.length === 0 ? (
        <Text style={styles.emptyText}>No rounds generated.</Text>
      ) : (
        rounds.map((r: any) => (
          <TouchableOpacity
            key={r.id}
            style={styles.listItem}
            onPress={() =>
              navigation.navigate("RoundDetail", {
                tournamentId: id,
                roundNumber: r.number,
              })
            }
          >
            <View>
              <Text style={styles.listItemText}>Round {r.number + 1}</Text>
              <View
                style={{
                  flexDirection: "row",
                  alignItems: "center",
                  marginTop: 4,
                }}
              >
                <Text style={styles.listItemSub}>
                  {r.pairings?.length || 0} pairings
                </Text>
                <Text
                  style={[
                    styles.statusBadge,
                    r.is_complete ? styles.statusFinished : styles.statusActive,
                  ]}
                >
                  {r.is_complete ? "Finished" : "Active"}
                </Text>
              </View>
            </View>
            <Text style={{ color: "#ccc", fontSize: 20 }}>›</Text>
          </TouchableOpacity>
        ))
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#fff",
  },
  container: {
    padding: 20,
    paddingBottom: 40,
  },
  center: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: 20,
  },
  titleContainer: {
    flex: 1,
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
  },
  subtitle: {
    fontSize: 16,
    color: "#666",
    marginTop: 5,
  },
  editButton: {
    backgroundColor: "#f0f0f0",
    paddingVertical: 8,
    paddingHorizontal: 15,
    borderRadius: 20,
    marginLeft: 10,
  },
  editButtonText: {
    color: "#007AFF",
    fontWeight: "600",
  },
  sectionHeader: {
    fontSize: 20,
    fontWeight: "bold",
    marginTop: 25,
    marginBottom: 10,
    color: "#333",
  },
  sectionRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginTop: 25,
    marginBottom: 10,
  },
  actionLink: {
    color: "#007AFF",
    fontSize: 16,
    fontWeight: "600",
  },
  disabledLink: {
    color: "#ccc",
  },
  descriptionContainer: {
    backgroundColor: "#f9f9f9",
    padding: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#eee",
  },
  descriptionBase: {
    fontSize: 16,
    color: "#444",
    lineHeight: 22,
  },
  errorText: {
    color: "red",
    fontSize: 16,
  },
  statsContainer: {
    flexDirection: "row",
    marginTop: 20,
    justifyContent: "space-around",
    backgroundColor: "#f9f9f9",
    borderRadius: 10,
    padding: 15,
  },
  statBox: {
    alignItems: "center",
  },
  statNumber: {
    fontSize: 24,
    fontWeight: "bold",
    color: "#007AFF",
  },
  statLabel: {
    color: "#666",
    fontSize: 12,
    marginTop: 2,
  },
  listItem: {
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#eee",
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  listItemText: {
    fontSize: 16,
    color: "#000",
  },
  listItemSub: {
    fontSize: 14,
    color: "#888",
  },
  deleteAction: {
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  deleteActionText: {
    color: "red",
    fontSize: 14,
  },
  actionButton: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    marginRight: 5,
  },
  emptyText: {
    color: "#999",
    fontStyle: "italic",
    marginTop: 5,
  },
  statusBadge: {
    fontSize: 12,
    fontWeight: "bold",
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
    overflow: "hidden",
    marginLeft: 10,
  },
  statusActive: {
    backgroundColor: "#e0f7fa",
    color: "#006064",
  },
  statusFinished: {
    backgroundColor: "#e8f5e9",
    color: "#1b5e20",
  },
  warningText: {
    color: "#ff9800",
    fontSize: 14,
    fontStyle: "italic",
    marginTop: -5,
    marginBottom: 10,
    textAlign: "right",
  },
});
