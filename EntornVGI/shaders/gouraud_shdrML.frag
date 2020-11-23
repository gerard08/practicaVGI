//******** PRACTICA VISUALITZACI� GR�FICA INTERACTIVA (EE-UAB)
//******** Entorn basic amb interf�cie MFC i Status Bar
//******** Enric Marti (Mar� 2020)
// gouraud_shdrML.frag: Fragment Program en GLSL per implementar il.luminacio de Gouraud en versi� OpenGL3.3

#version 330 core

// in Variables
in vec4 VertexColor;	// Color del V�rtex
in vec2 VertexTexCoord;	// Coordenades textura del v�rtex

// uniform Variables
uniform sampler2D texture0;	// Imatge textura
uniform bool textur;		// Booleana d�activaci� (TRUE) de textures o no (FALSE).
uniform bool modulate;		// Booleana d'activaci� de barreja color textura- color intensitat llum (TRUE) o nom�s color textura (FALSE)

// out Variables
out vec4 FragColor;		// Color fragment (r,g,b,a)

void main ()
{
if (textur) {	// Intensitat amb textura
		vec4 colorT = texture(texture0,VertexTexCoord);
		// Textura modulada amb intensitat llum
	    	if (modulate) FragColor = colorT * VertexColor;
       			else FragColor=colorT; // textura sense modular intensitat llum
    	    }
    else { // Intensitat sense textura
           FragColor = VertexColor;   
         }

}
