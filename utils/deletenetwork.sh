 Removing a Network from a Project

You will find that you cannot remove a network that has already been associated to a project by simply deleting it. You can disassociate the project from the network with a scrub command and the project name as the final parameter:


#nova-manage project scrub <projectID>
nova-manage project scrub 36167a5b422b421eb2d3621c1fa9586c

#nova-manage network delete <CIRD> <netUUID>
nova-manage network delete 192.168.2.129/25 a3b87e47-f093-40e7-b5dc-c64404b57885

