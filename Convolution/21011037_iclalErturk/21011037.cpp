#define _CRT_SECURE_NO_DEPRECATE
#include <stdio.h>
#include <stdlib.h>

// Function to print a matrix stored in a 1D array
void print_matrix(unsigned* matrix, unsigned rows, unsigned cols, FILE* file);
// Function to read matrix from a file
void read_matrix(const char* filename, unsigned** matrix, unsigned* rows, unsigned* cols);
// Function to read kernel from a file
void read_kernel(const char* filename, unsigned** kernel, unsigned* k);
// Function to write output matrix to a file
void write_output(const char* filename, unsigned* output, unsigned rows, unsigned cols);
// Initialize output as zeros.
void initialize_output(unsigned*, unsigned, unsigned);

int main() {

    unsigned n, m, k;  // n = rows of matrix, m = cols of matrix, k = kernel size
    // Dynamically allocate memory for matrix, kernel, and output
    unsigned* matrix = NULL;  // Input matrix
    unsigned* kernel = NULL;  // Kernel size 3x3
    unsigned* output = NULL;  // Max size of output matrix

    char matrix_filename[30];
    char kernel_filename[30];

    // Read the file names
    printf("Enter matrix filename: ");
    scanf("%s", matrix_filename);
    printf("Enter kernel filename: ");
    scanf("%s", kernel_filename);


    // Read matrix and kernel from files
    read_matrix(matrix_filename, &matrix, &n, &m);  // Read matrix from file
    read_kernel(kernel_filename, &kernel, &k);      // Read kernel from file

    // For simplicity we say: padding = 0, stride = 1
    // With this setting we can calculate the output size
    unsigned output_rows = n - k + 1;
    unsigned output_cols = m - k + 1;
    output = (unsigned*)malloc(output_rows * output_cols * sizeof(unsigned));
    initialize_output(output, output_rows, output_cols);

    // Print the input matrix and kernel
    printf("Input Matrix: ");
    print_matrix(matrix, n, m, stdout);

    printf("\nKernel: ");
    print_matrix(kernel, k, k, stdout);

    /******************* KODUN BU KISMINDAN SONRASINDA DEĞİŞİKLİK YAPABİLİRSİNİZ - ÖNCEKİ KISIMLARI DEĞİŞTİRMEYİN *******************/

    // Assembly kod bloğu içinde kullanacağınız değişkenleri burada tanımlayabilirsiniz. ---------------------->
    // Aşağıdaki değişkenleri kullanmak zorunda değilsiniz. İsterseniz değişiklik yapabilirsiniz.
    unsigned matrix_value, kernel_value;    // Konvolüsyon için gerekli 1 matrix ve 1 kernel değişkenleri saklanabilir.
    unsigned sum;                           // Konvolüsyon toplamını saklayabilirsiniz.
    unsigned matrix_offset;                 // Input matrisi üzerinde gezme işleminde sınırları ayarlamak için kullanılabilir.
    unsigned tmp_si, tmp_di, tmp_dx, tmp_bx, tmp_cx, tmp_ax;                // ESI ve EDI döngü değişkenlerini saklamak için kullanılabilir.
    matrix_offset = k / 2;
    sum = 0;
    // Assembly dilinde 2d konvolüsyon işlemini aşağıdaki blokta yazınız ----->

    /*for(i=0; i< output_rows; i++){
        for(j=0; j <output_cols; j++){
            for(k =0; k <kernelk; k++){
                for(l= 0; l <kernelk; l++){
                    sum += matrix[i + k][j + l] * kernel[k][l];
                }
            }
            output[i][j] = sum;
            sum = 0;
        }
    }*/

    __asm {
      
        XOR EDX, EDX//i
ENDIS:  
        
        XOR ECX, ECX//j
IKINCI:

        XOR EBX, EBX//k
UCUNCU:
        XOR ESI, ESI//l
DORDUNCU:
        //DX İ CX J BX K SI L
        MOV tmp_dx, EDX
        MOV tmp_cx, ECX
        MOV tmp_bx, EBX
        MOV tmp_si, ESI
        
        ADD EDX, EBX//matrix in satirini hesaplama
        ADD ECX, ESI//matrixin sutununu hesaplama
        MOV EAX, m
        MUL EDX
        ADD EAX, ECX//erisilecek adresi bulmak için hesaplanansatirla matrixin sutun sayisi carpilip hesaplanan sutun eklenmeli
        //mul4 her biri 4byte yer kapladigi icin
        MOV EDX, 4
        MUL EDX
        MOV EDI, [matrix]
        ADD EDI, EAX//matrixin adresine hesaplanan artis miktari eklenerek istenen goze ulasilir
        MOV EAX, [EDI]
        MOV tmp_ax, EAX//matrixteki istenen elaman saklanir

        MOV EAX, k
        MUL EBX//kernelin sutun sayisi ile istenen satir carpilir sonuc eax te
        ADD EAX, ESI//istenen sutun sonuca eklenir
        //4lecarp 4byte
        MOV EDX, 4
        MUL EDX
        MOV EDI, [kernel]
        ADD EDI, EAX//kernelin adresine bulunan sonuc eklenerek istenen goze ulasilir
        MOV EAX, [EDI]//kerneldeki deger eax e alinir

        MOV EDI, tmp_ax//matrixteki deger edıya alinir
        MUL EDI//konvolusyon islemi matrix*kernel sonuc eax te
        ADD sum, EAX//carpim sonucu sum a eklenir
        
        MOV EDX, tmp_dx 
        MOV EBX, tmp_bx
        MOV ECX, tmp_cx
        MOV ESI, tmp_si

        INC ESI
        CMP ESI, k
        JNE DORDUNCU

        INC EBX
        CMP EBX, k
        JNE UCUNCU
//       
        MOV tmp_dx, EDX

        MOV EAX, output_cols
        MUL EDX//i ile sutun sayisi carpilir
        ADD EAX, ECX//carpima j eklenir istenen goze ulasmak icin
        MOV EBX, 4
        MUL EBX//eaxte eklenecek adres

        MOV EBX, [output]
        ADD EBX, EAX//istenen gozun adresi hesaplanir
        MOV EAX, sum
        MOV [EBX], EAX//erisilen goze sum yerlestirilir
        MOV sum, 0
        
        MOV EDX, tmp_dx

        INC ECX
        CMP ECX, output_cols
        JNE IKINCI

        INC EDX
        CMP EDX, output_rows
        JNE ENDIS


    }
    /******************* KODUN BU KISMINDAN ÖNCESİNDE DEĞİŞİKLİK YAPABİLİRSİNİZ - SONRAKİ KISIMLARI DEĞİŞTİRMEYİN *******************/


    // Write result to output file
    write_output("./output.txt", output, output_rows, output_cols);

    // Print result
    printf("\nOutput matrix after convolution: ");
    print_matrix(output, output_rows, output_cols, stdout);

    // Free allocated memory
    free(matrix);
    free(kernel);
    free(output);

    return 0;
}

void print_matrix(unsigned* matrix, unsigned rows, unsigned cols, FILE* file) {
    if (file == stdout) {
        printf("(%ux%u)\n", rows, cols);
    }
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            fprintf(file, "%u ", matrix[i * cols + j]);
        }
        fprintf(file, "\n");
    }
}

void read_matrix(const char* filename, unsigned** matrix, unsigned* rows, unsigned* cols) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Error opening file %s\n", filename);
        exit(1);
    }

    // Read dimensions
    fscanf(file, "%u %u", rows, cols);
    *matrix = (unsigned*)malloc(((*rows) * (*cols)) * sizeof(unsigned));

    // Read matrix elements
    for (int i = 0; i < (*rows); i++) {
        for (int j = 0; j < (*cols); j++) {
            fscanf(file, "%u", &(*matrix)[i * (*cols) + j]);
        }
    }

    fclose(file);
}

void read_kernel(const char* filename, unsigned** kernel, unsigned* k) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Error opening file %s\n", filename);
        exit(1);
    }

    // Read kernel size
    fscanf(file, "%u", k);
    *kernel = (unsigned*)malloc((*k) * (*k) * sizeof(unsigned));

    // Read kernel elements
    for (int i = 0; i < (*k); i++) {
        for (int j = 0; j < (*k); j++) {
            fscanf(file, "%u", &(*kernel)[i * (*k) + j]);
        }
    }

    fclose(file);
}

void write_output(const char* filename, unsigned* output, unsigned rows, unsigned cols) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        printf("Error opening file %s\n", filename);
        exit(1);
    }

    // Write dimensions of the output matrix
    fprintf(file, "%u %u\n", rows, cols);

    // Write output matrix elements
    print_matrix(output, rows, cols, file);

    fclose(file);
}

void initialize_output(unsigned* output, unsigned output_rows, unsigned output_cols) {
    int i;
    for (i = 0; i < output_cols * output_rows; i++)
        output[i] = 0;
    
}

