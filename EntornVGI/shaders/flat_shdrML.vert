//******** PRACTICA VISUALITZACI� GR�FICA INTERACTIVA (EE-UAB)
//******** Entorn basic amb interficie MFC/GLFW amb Status Bar
//******** Enric Marti (Maig 2020)
// flat_shdrML.vert: Vertex Program en GLSL per implementar il.luminacio de Gouraud, en versi� OpenGL 3.3 o 4.00

#version 330 core
//#version 400 core

#define MaxLights 8

// Estructura fonts de llum
struct Light
{	bool sw_light;		// Booleana si font encesa (TRUE) o apagada (FALSE).
	vec4 position;		// Posici� de la font de llum (x,y,z,w).
	vec4 ambient;		// Intensitat ambient de la font de llum (r,g,b,a).
	vec4 diffuse;		// Intensitat difusa de la font de llum (r,g,b,a).
	vec4 specular;		// Intensitat especular de la font de llum (r,g,b,a).
	vec3 attenuation;	// Vector coeficients atenuaci� per dist�ncia (a,b,c).
	bool restricted;	// Booleana si font de llum restringida
	vec3 spotdirection;	// Vector director de la font de llum restringida.
	float cutoff;		// Angle d'obertura font de lum restringida.
	float exponent;		// Exponent d'obertura font de llum restringida segons model de Warn.
};

// Estructura coeficients reflectivitat de materials.
struct Material
{	vec4 emission;		// Coeficients reflexi� llum emissiva (r,g,b,a).
	vec4 ambient;		// Coeficients reflexi� llum ambient (r,g,b,a).
        vec4 diffuse;		// Coeficients reflexi� llum difusa (r,g,b,a).
	vec4 specular;		// Coeficients reflexi� llum especular (r,g,b,a).
	float shininess;	// Exponent reflexi� llum especular (n).
};

// --- L32
// in Variables
layout (location = 0) in vec3 in_Vertex; 	// Coordenades (x,y,z) posicio Vertex.
layout (location = 1) in vec3 in_Normal; 	// Coordenades (x,y,z) Vector Normal.
layout (location = 2) in vec2 in_TexCoord; 	// Coordenades (s,t) Coordenada textura.
layout (location = 3) in vec4 in_Color; 	// Coordenades (r,g,b,a) Color.
// --- L38
// Variables uniform
uniform mat4 normalMatrix;	// �the transpose of the inverse of the ModelViewMatrix.� 
uniform mat4 projectionMatrix;	// Projection Matrix.
uniform mat4 viewMatrix; 	// View Matrix.
uniform mat4 modelMatrix;	// Model Matrix.

uniform sampler2D texture0;	// Imatge textura
uniform bool textur;		// Booleana d�activaci� (TRUE) de textures o no (FALSE).
uniform bool fixedLight;	// Booleana que defineix la font de llum fixe en Coordenades M�n (TRUE) o no (FALSE).
uniform bvec4 sw_intensity;	// Filtre per a cada tipus de reflexi�: Emissiva (sw_intensity[0]), Ambient (sw_intensity[1]), Difusa (sw_intensity[2]) o Especular (sw_intensity[2]).
uniform vec4 LightModelAmbient;	// Intensitat de llum ambient (r,g,b,a)-
uniform Light LightSource[MaxLights];	// Vector de fonts de llum.
uniform Material material;	// Vector de coeficients reflectivitat de materials.
// --- L52
// Variables out
flat out vec4 VertexColor;
out vec2 VertexTexCoord;
// --- L56
void main ()
{

// --- L60- Calcul variables previes.
    //mat4 NormalMatrix = transpose(inverse(viewMatrix * modelMatrix));
    vec3 N = vec3(normalMatrix * vec4(in_Normal,1.0));
    N = normalize(N);
    vec3 vertexPV = vec3(viewMatrix * modelMatrix * vec4(in_Vertex,1.0));
    vec3 V = normalize(-vertexPV);

//-L66- Multiples llums
    vec3 ILlums = vec3 (0.0,0.0,0.0);	// Intensitat acumulada per a totes les fonts de llum.
    vec3 Idiffuse = vec3 (0.0,0.0,0.0);	// Intensitat difusa d�una font de llum.
    vec3 Ispecular = vec3 (0.0,0.0,0.0);	// Intensitat especular d�una font de llum.
    vec4 lightPosition = vec4(0.0,0.0,0.0,1.0);	// Posici� de la font de llum en coordenades Punt de Vista.
    vec3 L = vec3 (0.0,0.0,0.0);	// Vector L per a c�lcul intensitat difusa i especular.

//-L73- Textura
        //VertexTexCoord = in_TexCoord;
	VertexTexCoord = vec2(in_TexCoord.x,1.0-in_TexCoord.y); // SOIL_FLAG_INVERT_Y
 
//-L77- Compute emissive term
    vec3 Iemissive = vec3 (0.0,0.0,0.0);	// Intensitat emissiva de l�objecte.
    if (sw_intensity[0])  Iemissive = material.emission.rgb;

//-L81- Compute ambient term
    vec3 Iambient = vec3 (0.0,0.0,0.0);		// Intensitat ambient reflexada
    if (sw_intensity[1]) {	//Iambient = material.ambient.rgb * in_Color.rgb * LightModelAmbient.rgb;
				Iambient = material.ambient.rgb * LightModelAmbient.rgb;
        			Iambient = clamp(Iambient, 0.0, 1.0);
    			}

//-L87- Multiples llums
//    for (int i=0;i<gl_MaxLights;i++) {
    for (int i=0;i<MaxLights;i++) {
	if (LightSource[i].sw_light) { 
		//-L91- Compute light position (fixed in WC of attached to camera)
		if (fixedLight) lightPosition = viewMatrix * LightSource[i].position;
			else lightPosition = vec4(-vertexPV,1.0);
		//-L94- Compute point light source (w=1) or direccional light (w=0)
		if (LightSource[i].position.w == 1) {	//L = normalize(lightPosition.xyz - vertexPV);
							L = lightPosition.xyz - vertexPV;
							L = normalize (L);
						    }
                     else L = normalize(lightPosition.xyz);
		//vec3 L = normalize(LightSource[i].position.xyz - vertexPV);

		//-L98- Compute the diffuse term
		Idiffuse = vec3 (0.0,0.0,0.0);
     		if (sw_intensity[2]) {
        		float diffuseLight = max(dot(L, N), 0.0);
			//Idiffuse = material.diffuse.rgb * in_Color.rgb * LightSource[i].diffuse.rgb * diffuseLight;
			Idiffuse = material.diffuse.rgb * LightSource[i].diffuse.rgb * diffuseLight;
        		Idiffuse = clamp(Idiffuse, 0.0, 1.0);
     			}

		//-L106- Compute the specular term
    		Ispecular = vec3 (0.0,0.0,0.0);
    		if (sw_intensity[3]) {
        		//vec3 V = normalize(-vertexPV);
        		vec3 R = normalize(-reflect(L,N));
        		float specularLight = pow(max(dot(R, V), 0.0), material.shininess);
			//Ispecular = material.specular.rgb * in_Color.rgb * LightSource[i].specular.rgb * specularLight;
			Ispecular = material.specular.rgb * LightSource[i].specular.rgb * specularLight;
        		Ispecular = clamp(Ispecular, 0.0, 1.0);
    			}

   		ILlums += Idiffuse + Ispecular;
		}
   }
    
// --- L121- Transformacio de Visualitzacio amb Matriu Projeccio (projectionMatrix), Matriu C�mera (viewMatrix) i Matriu TG (modelMatrix)
    gl_Position = vec4(projectionMatrix * viewMatrix * modelMatrix * vec4(in_Vertex,1.0));

// ---L124- Calcul intensitat final del vertex
    VertexColor.rgb = Iemissive + Iambient + ILlums;
    VertexColor.a = 1.0;
}
