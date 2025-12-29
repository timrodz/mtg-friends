import React, { useLayoutEffect } from "react";
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from "react-native";
import { useTournaments } from "../hooks/useTournaments";
import { useNavigation } from "@react-navigation/native";
import { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { useAuthStore } from "../store/authStore";
import { RootStackParamList } from "../navigation/types";
import { tournamentBadge, tournamentFormat } from "../utils/tournaments/utils";

type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

export default function TournamentListScreen() {
  const {
    data,
    isLoading,
    error,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useTournaments();
  const navigation = useNavigation<NavigationProp>();
  const { isAuthenticated, logout } = useAuthStore();

  useLayoutEffect(() => {
    navigation.setOptions({
      headerRight: () => (
        <TouchableOpacity
          onPress={() => {
            if (isAuthenticated) {
              logout();
            } else {
              navigation.navigate("Login");
            }
          }}
          style={{ marginRight: 10 }}
        >
          <Text style={{ color: "#007AFF", fontSize: 16, fontWeight: "600" }}>
            {isAuthenticated ? "Logout" : "Login"}
          </Text>
        </TouchableOpacity>
      ),
    });
  }, [navigation, isAuthenticated]);

  if (isLoading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.errorText}>Failed to load tournaments</Text>
        <TouchableOpacity onPress={() => refetch()} style={styles.retryButton}>
          <Text style={styles.retryText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const tournaments = data?.pages.flatMap((page) => page.data) || [];

  return (
    <View style={styles.container}>
      <FlatList
        data={tournaments}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.item}
            onPress={() =>
              navigation.navigate("TournamentDetail", { id: item.id })
            }
          >
            <View style={styles.tournamentContainer}>
              <Text style={styles.itemTitle}>{item.name}</Text>
              <Text style={styles.itemSubtitle}>
                {tournamentFormat(item.format)} •{" "}
                {new Date(item.date).toLocaleDateString()}
              </Text>
            </View>
            <View>
              <Text style={styles.statusBadge}>
                {tournamentBadge(item.status)}
              </Text>
            </View>
          </TouchableOpacity>
        )}
        refreshing={isLoading}
        onRefresh={refetch}
        onEndReached={() => {
          if (hasNextPage) fetchNextPage();
        }}
        onEndReachedThreshold={0.5}
        ListFooterComponent={
          isFetchingNextPage ? (
            <ActivityIndicator size="small" color="#007AFF" />
          ) : null
        }
        ListEmptyComponent={
          <Text style={styles.emptyText}>No tournaments found.</Text>
        }
      />

      {isAuthenticated && (
        <TouchableOpacity
          style={styles.fab}
          onPress={() => navigation.navigate("TournamentCreate", {})}
        >
          <Text style={styles.fabText}>+</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f5f5f5",
  },
  centerContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  item: {
    backgroundColor: "white",
    padding: 15,
    marginHorizontal: 15,
    marginVertical: 8,
    borderRadius: 10,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  tournamentContainer: {
    maxWidth: "75%",
  },
  itemTitle: {
    fontWeight: "bold",
    fontSize: 16,
    marginBottom: 4,
  },
  itemSubtitle: {
    color: "#666",
    fontSize: 12,
  },
  statusBadge: {
    fontSize: 12,
    color: "#007AFF",
    fontWeight: "bold",
    backgroundColor: "#e0eaff",
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 12,
    overflow: "hidden",
  },
  fab: {
    position: "absolute",
    right: 20,
    bottom: 20,
    backgroundColor: "#007AFF",
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: "center",
    alignItems: "center",
    elevation: 5,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
  },
  fabText: {
    color: "white",
    fontSize: 24,
    fontWeight: "bold",
  },
  errorText: {
    color: "red",
    marginBottom: 10,
  },
  retryButton: {
    padding: 10,
    backgroundColor: "#007AFF",
    borderRadius: 5,
  },
  retryText: {
    color: "white",
  },
  emptyText: {
    textAlign: "center",
    marginTop: 50,
    color: "#888",
  },
});
