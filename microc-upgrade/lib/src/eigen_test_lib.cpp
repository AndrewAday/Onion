#include "eigen_test.h"

using namespace Eigen;


/* ============================ Utility Functions ============================== */

void onion_matrix_test(){
	MatrixXd tmp_m = MatrixXd::Constant(5, 5, 2.4);
	std::cout << tmp_m << std::endl;
}

MatrixXd* mat_cast(matrix_t undef_mptr){
	return static_cast<MatrixXd*>(undef_mptr);
}

void print_mat(matrix_t undef_mptr){
	MatrixXd* def_mptr = mat_cast(undef_mptr);
	std::cout << *def_mptr << std::endl;
}

int rows(matrix_t undef_mptr){
	MatrixXd* def_mptr = mat_cast(undef_mptr);
	return (*def_mptr).rows();
}

int cols(matrix_t undef_mptr){
	MatrixXd* def_mptr = mat_cast(undef_mptr);
	return (*def_mptr).cols();
}

/* ============================ Index and Slicing ============================== */

double mat_index(matrix_t undef_mptr, int r, int c) {
	MatrixXd* def_mptr = mat_cast(undef_mptr);
	return (*def_mptr)(r,c);
}

double mat_index_assign(matrix_t undef_mptr, int r, int c, double f) {
	MatrixXd* def_mptr = mat_cast(undef_mptr);
	(*def_mptr)(r,c) = f;
	return f;
}

/* ============================= Matrix Inititialization =============================== */

MatrixXd* init_fmat(const int d1, const int d2, const double c, const int op_id){
	MatrixXd* tmp_mptr = new MatrixXd;
	switch (op_id) {
		case 0: *tmp_mptr = MatrixXd::Zero(d1, d2); break;
		case 1: *tmp_mptr = MatrixXd::Constant(d1, d2, c); break;
		case 2: *tmp_mptr = MatrixXd::Identity(d2, d2); break;
	}

	return tmp_mptr;
}

matrix_t init_fmat_zero(const int d1, const int d2)						{return init_fmat(d1, d2, -1, 0);}
matrix_t init_fmat_const(const double c, const int d1, const int d2)	{return init_fmat(d1, d2, c, 1);}
matrix_t init_fmat_identity(const int d1, const int d2)					{return init_fmat(d1, d2, -1, 2);}
matrix_t init_fmat_literal(double * arr, const int d1, const int d2)	  {
		MatrixXd* tmp_mptr = new MatrixXd;
		(*tmp_mptr) = Map<MatrixXd>(arr, d1, d2);
		return tmp_mptr;
}

matrix_t copy(matrix_t undef_mptr){
	MatrixXd* tmp_mptr = new MatrixXd;
	MatrixXd* def_mptr = mat_cast(undef_mptr);
	*tmp_mptr = *def_mptr;
	return tmp_mptr;
}

void del_mat(matrix_t undef_mptr){
	MatrixXd *  def_ptr = mat_cast(undef_mptr);
	delete def_ptr;
}


/* ============================= Matrix Binary Operations =============================== */

MatrixXd* binary_operations(matrix_t undef_mptr1, matrix_t undef_mptr2, double scalar, int op_id){
	MatrixXd* def_mptr1 = mat_cast(undef_mptr1);
	MatrixXd* def_mptr2 = mat_cast(undef_mptr2);
	MatrixXd* tmp_mptr  = new MatrixXd;

	switch(op_id) {

		/* ======================== Matrix Matrix Operations ========================== */
		// matrix-matrix addition
		case 0: *tmp_mptr = *def_mptr1 + *def_mptr2; break;
		// matrix-matrix subtraction
		case 1: *tmp_mptr = *def_mptr1 - *def_mptr2; break;
		// matrix-matrix multiplication
		case 2: *tmp_mptr = (*def_mptr1).cwiseProduct(*def_mptr2); break;
		// matrix-matrix division
		case 3: *tmp_mptr = (*def_mptr1).cwiseQuotient(*def_mptr2); break;
		// matrix-matrix dot product
		case 4: *tmp_mptr = *def_mptr1 * *def_mptr2; break;

		/* ======================== Scalar Matrix Operations ========================= */

		// scalar matrix addition
		case 5: *tmp_mptr = (*def_mptr1).array() + scalar; break;
		// scalar matrix subtraction
		case 6: *tmp_mptr = (*def_mptr1).array() - scalar; break;
		case 7: *tmp_mptr = scalar - (*def_mptr1).array(); break;
		// scalar matrix multiplication
		case 8: *tmp_mptr = *def_mptr1 * scalar; break;
		// sclar matrix division
		case 9: *tmp_mptr = *def_mptr1 / scalar; break;
		case 10: *tmp_mptr = scalar  * (*def_mptr2).cwiseInverse(); break;
	}

	return tmp_mptr;
}

MatrixXd* binary_operations(matrix_t undef_mptr1, matrix_t undef_mptr2, int op_id){
	return binary_operations(undef_mptr1, undef_mptr2, 0, op_id);
}

MatrixXd* binary_operations(matrix_t undef_mptr, double scalar, int op_id){
	MatrixXd tmp_m;
	return binary_operations(undef_mptr, &tmp_m, scalar, op_id);
}

matrix_t mm_add(matrix_t undef_mptr1, matrix_t undef_mptr2)  { return binary_operations(undef_mptr1, undef_mptr2, 0); }
matrix_t mm_sub(matrix_t undef_mptr1, matrix_t undef_mptr2)  { return binary_operations(undef_mptr1, undef_mptr2, 1); }
matrix_t mm_mult(matrix_t undef_mptr1, matrix_t undef_mptr2) { return binary_operations(undef_mptr1, undef_mptr2, 2); }
matrix_t mm_div(matrix_t undef_mptr1, matrix_t undef_mptr2)  { return binary_operations(undef_mptr1, undef_mptr2, 3); }
matrix_t dot(matrix_t undef_mptr1, matrix_t undef_mptr2)		 { return binary_operations(undef_mptr1, undef_mptr2, 4); }

matrix_t sm_add(matrix_t undef_mptr, double s)					{ return binary_operations(undef_mptr, s, 5); }
matrix_t sm_sub(matrix_t undef_mptr, double s, int rev)	{ return rev ? binary_operations(undef_mptr, s, 6) :
																	   																	 binary_operations(undef_mptr, s, 7) ; }
matrix_t sm_mult(matrix_t undef_mptr, double s)					{ return binary_operations(undef_mptr, s, 8); }
matrix_t sm_div(matrix_t undef_mptr, double s, int rev)	{ return rev ? binary_operations(undef_mptr, s, 9) :
																	   																	 binary_operations(undef_mptr, s, 10) ; }



// matrix_t smeq(double s, matrix_t undef_mptr)	{ return binary_operations(undef_mptr, MatrixXd* tmp, s, 9); }

/* ============================= Matrix Unary Operations Operations =============================== */

matrix_t transpose(matrix_t undef_mptr){
	MatrixXd* def_mptr = mat_cast(undef_mptr);
	MatrixXd* tmp_mptr = new MatrixXd;

	*tmp_mptr = (*def_mptr).transpose();
	return tmp_mptr;
}

matrix_t negate(matrix_t undef_mptr){
	return sm_mult(undef_mptr, -1);
}
