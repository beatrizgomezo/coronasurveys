# Graph Sampler
This tool samples a subset of a graph by taking a random node and performing a breadth first search up to a specified number of hops. Then it returns the graph consisting of the retrieved nodes and all the edges between them (not only those involved in the BFS) from the original graph.


## Compiling
To compile you will need to have the snap source code in a snap subfolder (it can be a symlink) or you can edit the Makefile to suit your configuration.

Then you can run

     make

## Usage

To run the tool do as follows:

	./bin/graphSampler -g <graphFileName> -s <seedfilename> -l <number of hops> -o <outfilename>

or you can use SNAP's graph generator with the -G option:

    ./bin/graphSampler -G <graphgenstring> -s <seedfilename> -l <number of hops> -o <outfilename>

as of now, the code only supports random graphs and preferetial attachment graphs.

	<graphgenstring> = PrefA<numNodes>-<degree> | RndG<numNodes>-<numEdges>




