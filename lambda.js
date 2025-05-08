exports.handler = async (event) => {
    const response = {
      statusCode: 200,
      body: JSON.stringify("Hello from the new deployment yaml"),
    }
    return response
  }