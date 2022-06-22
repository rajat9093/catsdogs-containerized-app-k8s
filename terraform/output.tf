# Step 10 - Add output variables
output "public_ip" {
  value = aws_instance.my_amazon.public_ip
}