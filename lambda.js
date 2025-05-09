exports.handler = async (event) => {
    const response = {
      statusCode: 200,
      body: JSON.stringify("Hello from the PR testing pipeline"),
    }
    return response
  }