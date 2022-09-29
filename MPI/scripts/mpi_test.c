/* Based on the tutorial available in
 * https://mpitutorial.com/tutorials/mpi-hello-world/
 */

#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
    
    // initialize the MPI environment
    MPI_Init(NULL, NULL);

    // number of processors
    int size;
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // rank of the process
    int rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    // hostname
    char hostname[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(hostname, &name_len);

    // print the message
    printf("Host %s: rank %d out of %d processors\n", hostname, rank, size);

    // finalize the MPI environment.
    MPI_Finalize();
    
    return 0;
}
