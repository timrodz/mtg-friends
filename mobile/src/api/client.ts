export const API_URL = "http://localhost:4000/api";

export const login = async (email: string, password: string) => {
  try {
    const response = await fetch(`${API_URL}/login`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      throw new Error("Login failed");
    }

    return await response.json();
  } catch (error) {
    throw error;
  }
};

export const fetchTournaments = async (token: string) => {
  try {
    const response = await fetch(`${API_URL}/tournaments`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error("Failed to fetch tournaments");
    }

    return await response.json();
  } catch (error) {
    throw error;
  }
};
