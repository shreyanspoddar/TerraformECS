resource "aws_subnet" "PublicSubnet" {
  vpc_id                  = "${aws_vpc.ProjectVpc.id}"
  cidr_block             = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet"
  }
}
resource "aws_ecs_cluster" "foo" {
  name = "white-hart"

}
resource "aws_ecs_task_definition" "hello_world" {
  family                   = "hello-world-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = <<DEFINITION
[
  {
    "image":  "registry.gitlab.com/architect-io/artifacts/nodejs-hello-world:latest",
    # "cpu": 1024,
    # "memory": 2048,
    "name": "hello-world-app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ]
  }
]
DEFINITION
}
resource "aws_security_group" "hello_world_task" {
  name        = "example-task-security-group"
  vpc_id      = aws_vpc.ProjectVpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_ecs_service" "hello_world" { 
  name            = "hello-world-service"
  cluster         = aws_ecs_cluster.foo.id
  task_definition = aws_ecs_task_definition.hello_world.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.hello_world_task.id]
    subnets         = aws_subnet.PublicSubnet.*.id
    assign_public_ip = true

  
}

}
