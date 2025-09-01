resource "aws_vpc_peering_connection" "this" {
  vpc_id        = var.vpc_id_requester
  peer_vpc_id   = var.vpc_id_accepter
  auto_accept   = true
  tags          = merge(var.tags, { Name = var.name })
}

# Routes in requester -> accepter
resource "aws_route" "req_to_acc" {
  count = var.vpc_cidr_requester != var.vpc_cidr_accepter ? length(var.requester_private_rt_ids) : 0
  route_table_id            = var.requester_private_rt_ids[count.index]
  destination_cidr_block = var.vpc_cidr_accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# Routes in accepter -> requester
resource "aws_route" "acc_to_req" {
  count = var.vpc_cidr_requester != var.vpc_cidr_accepter ? length(var.accepter_private_rt_ids) : 0
  route_table_id            = var.accepter_private_rt_ids[count.index]
  destination_cidr_block = var.vpc_cidr_requester
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

output "peering_id" { value = aws_vpc_peering_connection.this.id }
