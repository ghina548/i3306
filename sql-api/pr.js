document.getElementById("loginForm").addEventListener("submit", async function(e) {
  e.preventDefault(); // prevent page refresh

  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value.trim();
  const errorMessage = document.getElementById("error-message");
  const submitButton = e.target.querySelector('button[type="submit"]');

  // Reset error message
  errorMessage.textContent = "";
  errorMessage.style.color = "red";

  // Simple frontend validation
  if (!email.includes("@")) {
    errorMessage.textContent = "Please enter a valid email.";
    return;
  }

  if (password.length < 4) {
    errorMessage.textContent = "Password must be at least 4 characters.";
    return;
  }

  // Disable submit button during request
  submitButton.disabled = true;
  submitButton.textContent = "Logging in...";

  try {
    // Send login request to backend
    const response = await fetch('http://localhost:3000/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ 
        email: email, 
        password: password 
      })
    });

    const data = await response.json();

    if (data.success) {
      // Login successful
      errorMessage.style.color = "green";
      errorMessage.textContent = "Login successful! Redirecting...";
      
      // Store user data in localStorage
      localStorage.setItem('currentUser', JSON.stringify(data.user));
      
      // Redirect based on role after 1 second
      setTimeout(() => {
    window.location.href = 'HomePage.html';  // Go to homepage instead
}, 1000);
      
    } else {
      // Login failed
      errorMessage.style.color = "red";
      errorMessage.textContent = data.message;
    }

  } catch (error) {
    console.error('Login error:', error);
    errorMessage.style.color = "red";
    errorMessage.textContent = "Connection error. Please check if the server is running.";
  } finally {
    // Re-enable submit button
    submitButton.disabled = false;
    submitButton.textContent = "Login";
  }
});