resource "aws_lambda_function" "test_lambda" {
    
    filename = "lambda_function_payload.zip"
    function_name = "test_lambda"
    role          = aws_iam_role.lambda_role.arn   
    handler = "index.test"

    source_code_hash = data.archive_file.lambda.output_base64sha256
    runtime = "nodejs18.x"

    environment {
        variables = {
            foo = "bar"
        }
    }

    provider = aws.SE-TESTING

    lifecycle {
      ignore_changes = [ 
        filename,
        source_code_hash,
       ]
    }
}